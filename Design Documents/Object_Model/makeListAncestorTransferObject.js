var fs = require("fs")

/*This function will create a ListAncestorTransferObject, ready to be received by the client. 
It will do this by compiling data from templeOrdinanceRecord and Ancestor JSON files.
*/
function makeListAncestorTransferObject(templeOrdinanceRecord, ancestor) {
    var listAncestorTransferObject = {
        ancestorId: ancestor.id,
        birthDate: ancestor.birthDate,
        deathDate: ancestor.deathDate,
        ordinancesToBeDone: templeOrdinanceRecord.ordinancesToBeDone
    }

    return listAncestorTransferObject
}

/* This function will get a Temple Ordinance Record from storage for a given ancestorId */
/**
 * getTempleOrdinanceRecord
 * This function retrieves the Temple Ordinance Record for a given ancestorId from file storage.
 * @param {String} ancestorId 
 * @returns Object
 */
function getTempleOrdinanceRecord(ancestorId, callback) {
    // Read the file for the given ancestorId
    fs.readFile(ancestorId + "_ordinanceRecord.json", function (error, data) {
        if (error) {
            throw error
        }

        var templeOrdinanceRecord = JSON.parse(data)

        callback(undefined, templeOrdinanceRecord)
    });
}

/**
 * getAncestor
 * This function retrieves the Ancestor object for a given ancestorId from file storage.
 * @param {String} ancestorId 
 * @returns Object
 */
function getAncestor(ancestorId, callback) {
    fs.readFile(ancestorId + "_ancestor.json", function (error, data) {
        if (error) {
            throw error
        }

        var ancestor = JSON.parse(data)

        callback(undefined, ancestor)
    });
}

function main() {
    // Get the Temple Ordinance Record
    getTempleOrdinanceRecord("KY12-LPM", function (recordError, templeOrdinanceRecord) {
        if (recordError) {
            console.log(recordError)
            return
        }
        getAncestor("KY12-LPM", function (ancestorError, ancestor) {
            if (ancestorError) {
                console.log(ancestorError)
                return
            }

            var listAncestorTransferObject = makeListAncestorTransferObject(templeOrdinanceRecord, ancestor)
            console.log(listAncestorTransferObject)
        })
    })
}

main()