var fs = require("fs")

/*This function will create a ListAncestorTransferObject, ready to be received by the client. 
It will do this by compiling data from templeOrdinanceRecord and Ancestor JSON files.
*/
function makeAncestorListTransferObject(ancestorRecord) {
    return {
        ancestorId: ancestorRecord.id,
        name: ancestorRecord.name,
        birthDate: ancestorRecord.birthDate,
        deathDate: ancestorRecord.deathDate,
        ordinancesToBeDone: ancestorRecord.ordinancesToBeDone
    }
}

/* This function will get a Temple Ordinance Record from storage for a given ancestorId */
/**
 * getAncestorRecord
 * This function retrieves the Ancestor Record for a given ancestorId from file storage.
 * @param {String} ancestorId 
 * @returns Object
 */
function getAncestorRecord(ancestorId, callback) {
    // Read the file for the given ancestorId
    var ancestorRecord = fs.readFileSync(ancestorId + "_ancestorRecord.json")

    ancestorRecord = JSON.parse(ancestorRecord)
    return ancestorRecord
}

function main() {
    // Get the Temple Ordinance Record
    var ancestorRecord = getAncestorRecord("KY12-LPM")
    var listAncestorTransferObject = makeAncestorListTransferObject(ancestorRecord)
    console.log(listAncestorTransferObject)
}

main()