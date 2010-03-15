// (C) 2009 Magna Powertrain
// contact: Rene Schickbauer

// This script file holds various helper functions
// commonly used in Maplat forms

function confirmLogout() {
    return confirm("Do you really want to logout?");
}

function confirmDeleteUser() {
    return confirm("Do you really want delete this user?");
}

function confirmChangeUser() {
    return confirm("Do you really want change this users settings?");
}

function confirmCreateMapping() {
    return confirm("Do you really want to create this mapping?");
}

function confirmChangeMapping() {
    return confirm("Do you really want to change this mapping?");
}

function confirmDeleteUnmapped(elemID) {
    if(confirm("Do you really want to DELETE this signals?")) {
        if(!confirm("DELETING THIS SIGNALS CAN NOT BE UNDONE!\n\nAre you sure you really, really, REALLY want to delete?")) {
            return false;
        }
        var modeElem = document.getElementById(elemID);
        modeElem.value = "deleteunmapped";
        return true;

    } else {
        return false;
    }
}


function confirmDeleteFilter(elemID) {
    if(!confirm("Do you really want to delete this filter?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    modeElem.value = "deletefilter";
    return true;
}

function confirmDeleteCompany(elemID) {
    if(!confirm("Do you really want to delete this Company?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    modeElem.value = "deletecompany";
    return true;
}

function confirmDeleteLine(elemID) {
    if(!confirm("Do you really want to delete this ProdLine?")) {
        return false;
    }
    if(!confirm("DELETING THIS PRODLINE DELETES ALL USER RIGHTS FOR THIS LINE!\n\nAre your really sure you want to do this?")) {
        return false;
    }
    
    var modeElem = document.getElementById(elemID);
    modeElem.value = "deleteline";
    return true;
}

function confirmDeleteCard(elemID) {
    if(!confirm("Do you really want to delete this Chipcard?")) {
        return false;
    }
    
    var modeElem = document.getElementById(elemID);
    modeElem.value = "deletecard";
    return true;
}

function confirmDeleteDocument(elemID) {
    if(!confirm("Do you really want to delete this document?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    modeElem.value = "delete";
    return true;
}

function setMode(elemID, modeVal) {
    var modeElem = document.getElementById(elemID);
    modeElem.value = modeVal;
    return true;
}

function confirmDeleteAFMFilePara(elemID) {
    if(!confirm("Do you really want to delete this item?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    modeElem.value = "delete";
    return true;
}

function confirmDeleteAFMProjectConfiguration(elemID) {
    if(!confirm("Do you really want to delete this item?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    modeElem.value = "delete";
    return true;
}

function confirmDeleteAFMProject(elemID) {
    if(!confirm("Do you really want to delete this project?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    modeElem.value = "delete";
    return true;
}

function confirmDeleteAFMConnectorNodes(elemID, line_id) {
    if(!confirm("Do you really want to delete this node combination?")) {
        return false;
    }
    var modeElem = document.getElementById(elemID);
    var str1="delete;"
    var str2=line_id;
    
    modeElem.value = str1.concat(str2);
    return true;
}

function confirmAddAFMConnectorNodes(elemID, line_id) {

    var modeElem = document.getElementById(elemID);
    modeElem.value = "add";
    return true;
}

function confirmAddAFMConnector(elemID, line_id) {
    if(!confirm("Do you really want to add this connector?")) {
        return false;
    }

    var modeElem = document.getElementById(elemID);
    modeElem.value = "addconnector";
    return true;
}

function confirmAddAFMTie(elemID, line_id) {
    if(!confirm("Do you really want to add this tie?")) {
        return false;
    }

    var modeElem = document.getElementById(elemID);
    modeElem.value = "addtie";
    return true;
}

function confirmCheckAFMTieSurfaces(elemID, line_id) {

    var modeElem = document.getElementById(elemID);
    modeElem.value = "check_surface";
    return true;
}

function serializeList(listID, inputID) {
	var listElems = $(listID).sortable('toArray');
	var listString = listElems.join(";");
	var modeElem = document.getElementById(inputID);
	modeElem.value = listString;
	return true;
}

function confirmDeleteReport(elemID) {
    if(!confirm("Do you really want to delete this Report?")) {
        return false;
    }
    
    var modeElem = document.getElementById(elemID);
    modeElem.value = "deletereport";
    return true;
}