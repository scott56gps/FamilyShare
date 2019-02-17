const express = require('express')
const multer = require('multer')
const aws = require('aws-sdk')
const app = express()
var expressWs = require('express-ws')(app);

// Configure Postgres
const { Pool } = require('pg')
const pool =  new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: true
})

// Configure AWS authentication
aws.config.update({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || awsAccessKeyId,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || awsSecretAccessKey
})

const s3 = new aws.S3()

// Configure body-parser
const bodyParser = require('body-parser')
app.use(bodyParser.json())

// Configure Multer
var storage = multer.memoryStorage()

const upload = multer({
    storage: storage
})

const port = process.env.PORT || 5000;

function savePdfToAWS(data, callback) {
    var params = {
        Bucket: process.env.S3_BUCKET_NAME || bucketName,
        Key: data.key,
        Body: data.value,
        ContentType: 'application/pdf'
    }

    s3.upload(params, (error, data) => {
        if (error) {
            console.log(error)
            callback(error, undefined)
        }

        console.log("Data uploaded to:", data.Location)
        callback(undefined, 'Data uploaded to: ' + data.Location)
    })
}

function makeTempleCardTransferObject(value, key) {
    return {
        key: key,
        value: value
    }
}

function loadPdfFromAWS(fsId, callback) {
    var params = {
        Bucket: process.env.S3_BUCKET_NAME || bucketName, 
        Key: `${fsId}.pdf`
    };

    s3.getObject(params, (error, data) => {
        if (error) {
            callback(error)
        } else {
            console.log('Got Data!')
            callback(undefined, data.Body)
        }
    })
}

app.get('/', (request, response) => {
    response.send("Welcome to the App!  This is an example database querying app with the potential to become the production server")
})

app.get('/exampleQuery', async (request, response) => {
    try {
        const client = await pool.connect()
        const result = await client.query('SELECT user_id FROM "user" WHERE user_id = 1');
        response.send(result.rows[0])
        client.release()
    } catch (err) {
        console.error(err);
        response.send("Error " + err);
    }
})

app.get('/available', async (request, response) => {
    try {
        const client = await pool.connect()
        const result = await client.query("SELECT * FROM ancestor WHERE user_id IS NULL")
        console.log(result.rows)
        response.send(result.rows)
        client.release()
    } catch (err) {
        console.error(err);
        response.send("Error " + err);
    }
})

app.get('/reserved/:userId', async (request, response) => {
    try {
        var userId = request.params.userId

        const client = await pool.connect()
        const result = await client.query(`SELECT * FROM ancestor WHERE user_id = ${userId};`)
        console.log(result.rows)
        client.release()
        response.send(result.rows)
    } catch (err) {
        console.error(err);
        response.send("Error " + err);
    }
})

app.post('/createUser/:username', async (request, response) => {
    var username = request.params.username
    
    try {
        const client = await pool.connect()
        await client.query(`INSERT INTO "user"(username) VALUES ('${username}')`)
        const result = await client.query(`SELECT user_id FROM "user" WHERE username = '${username}'`)
        console.log(result.rows)
        response.send(result.rows)
        client.release()
    } catch (err) {
        console.error(err)
        response.status(500)
        response.json({"error": err})
    }
})

app.post('/share', upload.single('templePdf'), async (request, response) => {
    var givenNames = request.body.givenNames
    var surname = request.body.surname
    var familySearchId = request.body.familySearchId
    var ordinanceNeeded = request.body.ordinanceNeeded
    var gender = request.body.gender

    // Ensure request is valid
    console.log('INSERT INTO ancestor(given_name, surname, ordinance_needed, user_id, fs_id, gender) ' +
    'VALUES ' +
    `('${givenNames}', '${surname}', '${ordinanceNeeded}', NULL, '${familySearchId}', ` +
    `'${gender}');`)

    try {
        // Put Ancestor in the database
        const client = await pool.connect()
        await client.query('INSERT INTO ancestor(given_name, surname, ordinance_needed, user_id, fs_id, gender) ' +
        'VALUES ' +
        `('${givenNames}', '${surname}', '${ordinanceNeeded}', NULL, '${familySearchId}', ` +
        `'${gender}');`)
        client.release()

        // Put Temple Card in File Storage
        var templeCardDto = makeTempleCardTransferObject(request.file.buffer, `${request.body.familySearchId}.pdf`)
        savePdfToAWS(templeCardDto, (err, res) => {
            if (err) {
                console.log("ERROR in saving Temple Card to AWS:", err)
                response.send(err)
                return
            }

            response.send(res)
        })
    } catch (err) {
        console.log(err)
        response.send(err)
    }
})

app.post('/reserve', upload.none(), async (request, response) => {
    try {
        // const ancestorId = request.params.ancestorId
        // const userId = request.params.userId
        console.log(request.body.id)
        console.log(request.body.userId)
        var ancestorId = request.body.id
        var userId = request.body.userId

        const client = await pool.connect()

        // Query the ancestorId that came through
        const result = await client.query(`SELECT fs_id FROM ancestor WHERE id = ${ancestorId} AND user_id IS NULL`)

        // First, reserve the ancestor for this user
        if (result.rows.length == 1 && userId != undefined) {
            console.log('We found the fs_id for the requested ancestor!')
            var fsId = result.rows[0]['fs_id']

            // Reserve the ancestor by updating the user_id column for this ancestorId
            const updateResult = await client.query(`UPDATE ancestor SET user_id = ${userId} WHERE id = ${ancestorId}`)

            client.release()
            response.send({ "fs_id": fsId })
        } else {
            client.release()
            response.send({ "Error": "Either the ancestorId or userId was undefined" })
        }
    } catch (err) {
        console.error(err);
        response.send("Error " + err);
    }
})

app.get('/templeCard/:userId/:ancestorId', async (request, response) => {
    console.log('userId:', request.params.userId)
    console.log('ancestorId:', request.params.ancestorId)
    var userId = request.params.userId
    var ancestorId = request.params.ancestorId

    // Check to see if the user is associated with this ancestor
    try {
        const client = await pool.connect()

        const result = await client.query(`SELECT * FROM ancestor WHERE user_id = ${userId} AND id = ${ancestorId};`)
    
        var fsId = result.rows[0]['fs_id']
        console.log('fs_id', fsId)
        if (result.rows.length == 1) {
            // Proceed with the download
            loadPdfFromAWS(fsId, (err, data) => {
                if (err) {
                    console.log("ERROR!")
                    console.log(err)
                    client.release()
                    response.send(err)
                }
                response.writeHead(200, {
                    'Content-Type': 'application/pdf',
                    'Content-Disposition': `attachment; filename=${fsId}.pdf`,
                    'Content-Length': data.length
                });
                client.release()
                response.end(data)
            })
        } else {
            response.send('ERROR: User is not associated with this ancestor')
        }
    } catch (err) {
        console.error(err)
        response.send("Error " + err)
    }
})

app.get('/login/:username', async (request, response) => {
    try {
        var username = request.params.username
        console.log('username:', username)

        const client = await pool.connect()

        // Query the username that came through
        const result = await client.query(`SELECT * FROM "user" WHERE username = '${username}'`)
        
        if (result.rows.length > 0 && result.rows[0]['username'] == username) {
            console.log('User found!')

            //var userId = result.rows[0]['user_id']

            //var stringifiedUserId = JSON.stringify(userId)

            console.log(result.rows)
            response.send(result.rows)
        } else {
            response.send('User not found')
        }
        client.release()
    } catch (err) {
        console.error(err);
        response.send("Error " + err);
    }
})

app.ws('/route1', (ws, request) => {
    ws.on('open', (message) => {
        console.log('I just received this message', message);
        ws.send('Connection for route1 is opened');
    });

    ws.on('message', (message) => {
        console.log('Here is a message', message);
    });

    ws.on('close', (message) => {
        console.log('Route 1 is closing');
    })
})

app.ws('/route2', (ws, request) => {
    ws.on('open', (message) => {
        console.log('I just received this message for route2', message);
        ws.send('Connection for route2 is opened');
    });

    ws.on('message', (message) => {
        console.log('Here is a message for route2', message);
    });

    ws.on('close', (message) => {
        console.log('Route 2 is closing');
    })
})

app.ws('/reserve', (ws, request) => {
    ws.on('open', (message) => {
        console.log('I just received this message for route2', message);
        ws.send('Connection for reserve is opened');
    });

    ws.on('message', upload.none(), async (request, response) => {
        console.log('Message received in reserve', request);
        // var givenNames = request.body.givenNames
        // var surname = request.body.surname
        // var familySearchId = request.body.familySearchId
        // var ordinanceNeeded = request.body.ordinanceNeeded
        // var gender = request.body.gender

        // // Ensure request is valid
        // console.log('INSERT INTO ancestor(given_name, surname, ordinance_needed, user_id, fs_id, gender) ' +
        // 'VALUES ' +
        // `('${givenNames}', '${surname}', '${ordinanceNeeded}', NULL, '${familySearchId}', ` +
        // `'${gender}');`)

        // try {
        //     // Put Ancestor in the database
        //     const client = await pool.connect()
        //     await client.query('INSERT INTO ancestor(given_name, surname, ordinance_needed, user_id, fs_id, gender) ' +
        //     'VALUES ' +
        //     `('${givenNames}', '${surname}', '${ordinanceNeeded}', NULL, '${familySearchId}', ` +
        //     `'${gender}');`)
        //     client.release()

        //     // Put Temple Card in File Storage
        //     var templeCardDto = makeTempleCardTransferObject(request.file.buffer, `${request.body.familySearchId}.pdf`)
        //     savePdfToAWS(templeCardDto, (err, res) => {
        //         if (err) {
        //             console.log("ERROR in saving Temple Card to AWS:", err)
        //             response.send(err)
        //             return
        //         }

        //         response.send(res)
        //     })
        // } catch (err) {
        //     console.log(err)
        //     response.send(err)
        // }
    });

    ws.on('close', (message) => {
        console.log('Route 2 is closing');
    })
})

app.listen(port, () => {
    console.log(`Server now listening on port ${port}`)
})