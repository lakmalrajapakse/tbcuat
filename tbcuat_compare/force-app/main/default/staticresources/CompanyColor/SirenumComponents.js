var clickAttached = false;

function closeWindow(elem) {
	elem.parentNode.parentNode.parentNode.parentNode.removeChild(elem.parentNode.parentNode.parentNode);
}

function showPage(c) {
	showPageIframe(c);
}

function gotoId(id) {
	window.open("/" + id);
}

function goToScheduling() {
	window.open("apex/ShiftScheduling2?view=4");
}

function loadingCursor() {
	document.body.style.cursor = "progress";
}

function defaultCursor() {
	document.body.style.cursor = "default";

}

function reloadFrame() {
	window.top.location.reload();
}

function showOptions(div, event) {

	if(!clickAttached){
		window.top.addEventListener("click",closeIframeMenus, false);
		clickAttached = true;
	}
	if (div.firstChild.nextSibling.style.display == 'none'){
		div.firstChild.nextSibling.style.display = 'block';
		if(window.event)
			window.event.stopPropagation();
	}else{
		div.firstChild.nextSibling.style.display = 'none';
		if(window.event)
			window.event.stopPropagation();
	}
	var matches = [];
	var searchEles = div.parentNode.parentNode.children;

	for(var i = 0; i < searchEles.length; i++) {
    var childrenDiv = searchEles[i].children;
    for(var j=0; j< childrenDiv.length; j++){
        if(childrenDiv[j].id.indexOf('close_') == 0 && childrenDiv[j].id != div.id) {
            matches.push(childrenDiv[j]);
        }
    }
  }

  for(var k = 0; k<matches.length;k++){
    var closeMenu = matches[k].firstChild.nextSibling;
    var display = closeMenu.style.display;
    if(display == 'block' ){
      closeMenu.style.display = "none";
    }
  }

}


function closeMenus(div){
		var matches = [];
		var searchEles = div.children;
		for(var i = 0; i < searchEles.length; i++) {
						var childrenDiv = searchEles[i].children;
						for(var j=0; j< childrenDiv.length; j++){

								if(childrenDiv[j].id.indexOf('close_') == 0) {
										matches.push(childrenDiv[j]);
								}
						 }

		}

	 for(var k = 0; k<matches.length;k++){
				var closeMenu = matches[k].firstChild.nextSibling;
				var display = closeMenu.style.display;
				if(display == 'block'){
						showOptions(matches[k]);
				}

	 }
}


function closeIframeMenus(){
	  var div = document.getElementById("cardsPanel");
		console.log(div);
		closeMenus(div);
}

function removeCard(cardType) {
	hideCard(cardType);
}

function getContacts(letter) {
	changeContacts(letter);
}

function getSites(letter) {
	changeSites(letter);
}

function getTeams(letter) {
	changeTeams(letter);
}

/* Iframe resizing */
var autoResizeTimer = null;
var autoResizeLoop = false;
function autoResize() {
    try {
        autoResizeTimer = null;
        var newheight = document.body.scrollHeight;

        if (window.top != window) {
            autoResizeLoop = true;
            window.frameElement.style.height = (newheight) + "px";
            setTimeout(resetAutoResizeLoop, 100);
        }
    } catch(ex) {}
}

function resetAutoResizeLoop() {
    autoResizeLoop = false;
}

function resizeEvent(e) {
    if (autoResizeTimer == null && !autoResizeLoop) {
        autoResizeTimer = setTimeout(autoResize, 100);
    }
}

/* Change Favicon */
function setSirenumFavicon() {
	var link = null, links;
	links = document.getElementsByTagName("link");
	for (var i=0;i<links.length;i++) {
		if (links[i].rel == "shortcut icon") {
			link = links[i];
			break;
		}
	}

	if (link == null) {
		link = document.createElement('link');
		link.rel = "shortcut icon";
		document.getElementsByTagName("head")[0].appendChild(link);
	}

	link.type = "image/png";
	link.href = "/resource/sirenum__Sirenum/favicon-32x32.png";
}

function sirenumSetupIframeResize() {
	// iFrame detection -- call auto resize on frame resize
	if (window.top != window) {
		window.addEventListener("resize", resizeEvent, false);
		resizeEvent();
		setInterval(autoResize, 3000);
	}
}

function initializeSirenumPage(framing) {
	if (framing) {
		sirenumSetupIframeResize();
	}

	setSirenumFavicon();
}

window.addEventListener("load", function() {initializeSirenumPage(false);});

function setPageLoading(value) {
	document.getElementById("sirenumFullPageLoader").style.display = (value) ? "block" : "none";
}

/**
 * Converts the given time string, with optional day offset applied against the start date. The
 * time string components must be within valid ranges (hours in range [0..24] and minutes in
 * range [0..59]) otherwise NaN is returned.
 *
 * @param strTime the time string. Must not be null and should be in one of the accepted
 *                formats (including optional AM/PM markers). The AM/PM markers are either
 *                standard English values or, when defined, the Label.AnteMeridiem
 *                and Label.PostMeridiem strings
 * @param day     the offset in days from the "start date" (this being either today or, when
 *                defined, the globalSettings.start value). May be undefined in order to apply
 *                no offset
 * @return {Date|Number} the given time as a Date based on the specified day offset - or NaN if invalid
 */
function parseTime(strTime, day) {
	let amText = (window.Label ? Label.AnteMeridiem.toLowerCase() : null) || "a";
	let pmText = (window.Label ? Label.PostMeridiem.toLowerCase() : null) || "p";
	let startDate = window.globalSettings ? globalSettings.start : Date.now();
	let pm = false;
	let am = false;

	if (!strTime) {
		strTime = "00:00";
	}

	strTime = strTime.trim().toLowerCase();

	// Check for AM/PM suffixes
	let posP = strTime.indexOf(pmText);
	let posA = strTime.indexOf(amText);

	// Get AM/PM part
	if (posP > 0) {
		pm = true;
		strTime = strTime.substr(0, posP);
	} else if (posA > 0) {
		am = true;
		strTime = strTime.substr(0, posA);
	}

	strTime = strTime.trim();

	if (strTime < 0 || strTime > 2400) {
		return NaN;
	}

	// Get minutes
	let h;
	let m = strTime.substr(-2);
	strTime = strTime.substr(0, strTime.length - 2);

	if (strTime.length > 0) {
		// Convert minutes to number
		m = Number(m);

		// Convert the rest of the text to hours
		if (strTime.substr(strTime.length - 1) === ":") {
			strTime = strTime.substring(0, strTime.length - 1);
		}

		h = Number(strTime);
	} else {
		h = Number(m);
		m = 0;
	}

	if (h < 0 || h > 24 || m < 0 || m > 59) {
		return NaN;
	}

	if (pm && h < 12) {
		h += 12;
	} else if (am && h >= 12) {
		h -= 12;
	}

	let dtTime = new Date(startDate);

	if (day) {
		dtTime.setDate(dtTime.getDate() + day);
	}

	dtTime.setHours(h);
	dtTime.setMinutes(m);
	dtTime.setSeconds(0);

	// Check for invalid date
	if (isNaN(dtTime.getTime())) {
		return NaN;
	}

	return dtTime;
}

/* String Format */
if (!String.prototype.format) {
  String.prototype.format = function() {
    var args = arguments;
    return this.replace(/{(\d+)}/g, function(match, number) { 
      return typeof args[number] != 'undefined'
        ? args[number]
        : match
      ;
    });
  };
}

/**
 * Recursively removes the namespace prefix and custom field suffix from the specified object's property names.
 *
 * @param item the object (or primitive value - these are ignored) for which property names are to be updated to
 *             remove namespace prefixes and custom field suffixes. Must not be null
 */
function removeNamespace(item) {
	if (typeof item != "object") {
		return;
	}

	for (var fld in item) {
		// Recurse to child value
		removeNamespace(item[fld]);

		// Find the namespace prefix and/or custom field suffix in the field name and remove them
		var newField = fld;

		// Remove any namespace prefix first (don't want to impact any fields starting with "c" that
		// are in the namespace)
		if (newField.indexOf("sirenum__") == 0) {
			// This explicit use of the prefix for the length ensures that namespaces are handled
			// with prefix mapping
			newField = newField.substring("sirenum__".length);
		}


		// Remove trailing __c
		if (newField.length > 3 && newField.indexOf("__c") === newField.length - 3) {
			newField = newField.substring(0, newField.length - 3);
		}

		if (newField != fld) {
			item[newField] = item[fld];

			delete item[fld];
		}
	}
}

/**
 * Find the first scrollable parent, but not the window
 * @param {Node} node
 * @return {Node|null}
 */
function getScrollParent(node) {
	if (node == null || node === window || node === document.body) {
		return null;
	}

	if (node.scrollHeight > node.clientHeight) {
		return node;
	} else {
		return getScrollParent(node.parentNode);
	}
}

function scrollIntoViewIfNeeded(elem) {
	var rect = elem.getBoundingClientRect();
	var container = getScrollParent(elem);
	if (container) {
		var containerRect = container.getBoundingClientRect();
		if (rect.bottom > containerRect.bottom) {
			elem.scrollIntoView(false);
		}
		if (rect.top < containerRect.top) {
			elem.scrollIntoView();
		}
	}
}

/**
 * Prepares a list of Ids for transmission to the server with a focus on minimising the payload.
 * Shortens each ID to 15 characters. Note that this makes the IDs case-sensitive.
 * Performs compression if enabled.
 * Serializes the result and strips inner quotes to avoid needing to add escape characters.
 *
 * @param {String[]} ids the ids to be prepared.
 * @returns {String} a string literal representing an array containing the formatted ids.
 */
function prepareIdsForTransmission(ids) {
	let formattedIds = ids.map(id => id.substring(0,15));

	if (!(window.globalSettings && globalSettings.skipCompressionOfIds)) {
		formattedIds = compressStrings(formattedIds);
	}

	return JSON.stringify(formattedIds).replace(/"/g, '');
}


/**
 * Applies simplified compression to a list of strings.
 * The strings will be grouped by common prefixes and these prefixes will then be stripped from individual strings
 * to reduce overall size.
 * The result will be a tree-like structure where each node can either be a leaf (String) or branch (List).
 * The first node in every branch will be a leaf. This is a substring which is common to all the other nodes in
 * this branch.
 * Each following node in the branch should be prefixed with the string from this first leaf to gradually build
 * up complete strings.
 * Each node after the first can either be a leaf or another branch. If it is a leaf then it represents the
 * last character(s) in the string. If it is a branch then the logic above is repeated.
 *
 * In practice it looks like this:
 * Strings: [Jade, Jake, Jennifer, Jenny, Judy, Juliet, Margaret, Marilyn, Mary, Medusa, Micky, Mike, Minnie, Veronica]
 * Compression result: [Veronica, [J, [a, de, ke], [en, nifer, ny], [u, dy, liet]], [M, [ar, garet, ilyn, y], edusa, [i, cky, ke, nnie]]]
 *
 * @param {String[]} strings the strings to be compressed.
 * @returns {*[]} a tree of compressed strings.
 */
function compressStrings(strings) {

	let getCommonStart = (str1, str2) => {
		const maxLength = Math.max(str1.length, str2.length);
		let i = 0;
		while (i < maxLength && str1.charAt(i) === str2.charAt(i)) {
			i++
		}
		return str1.substring(0, i)
	};

	let reduceString = (node, string) => {
		// Find the key that share a common start with the id (there can only be one key with common start)
		let commonKey = '';
		let foundKey = Object.keys(node).find(key => {
			let commonStart = getCommonStart(key, string);
			commonKey = commonStart || '';
			return !!commonStart;
		});

		if (foundKey) {
			// We found existing key, get the sub node
			let subNode = node[foundKey];
			if (foundKey === commonKey) {
				// existing key is the common key, just reduce further
				reduceString(subNode, string.substring(commonKey.length));
			} else {
				// Split the node to the common key
				delete node[foundKey];
				node[commonKey] = {
					[foundKey.substring(commonKey.length)]: subNode,
					[string.substring(commonKey.length)]: {}
				};
			}
		} else {
			// no key, create a new empty node
			node[string] = {};
		}
		return node;
	};

	let mapNodeToArray = (node) => {
		return Object.keys(node).map(key => {
			let values = mapNodeToArray(node[key]);
			if (values.length) {
				return [key].concat(values);
			} else {
				return key;
			}
		});
	};

	return mapNodeToArray(strings.reduce(reduceString, {}));
}

/*
 **********************************************************************************************************************
 * AUTO COMPLETION CODE FOLLOWS
 **********************************************************************************************************************
 */

// TODO Maybe refactor this object to be a class where the initializeElement method is the constructor and it retains a reference to the linked input element so that we no longer have to pass it around as a parameter in various methods. Note that we should still have only one dropdown div in the page.
/**
 * Global variable which holds properties and methods used by the autocomplete component.
 */
var SirenumAutoComplete = {

	/**
	 * Holds the results obtained from auto-completion. These results are set when results are available from
	 * the server and used when handling the keyboard shortcut events.
	 */
	results: [],

	/**
	 * Holds a count of how many pages we have loaded into the current auto-completion results.
	 */
	numPagesLoaded: 0,

	/**
	 * The index of the currently selected item in the results list.
	 */
	indexOfSelectedItem: null,

	/**
	 * A counter used for detecting stale queries.
	 */
	queryVersion: 0,

	/**
	 * Have we retrieved all matching records from the server.
	 */
	fullyLoaded: false,

	/**
	 * Number of columns in the results list.
	 */
	numberOfColumns: 0,

	/**
	 * Closes any existing auto-completion results list.
	 */
	close: function () {
		var autoCompleteDiv = document.getElementById("sirenumAutoCompleteDiv");

		if (autoCompleteDiv) {
			autoCompleteDiv.parentNode.removeChild(autoCompleteDiv);
		}
	},

	/**
	 * Is the dropdown list open (visible)
	 *
	 * @returns {boolean} is the dropdown list open
	 */
	isDropdownOpen: function() {
		return !!document.getElementById("sirenumAutoCompleteDiv");
	},

	/**
	 * Highlights the row at the specified index, records the index as being selected
	 * and removes highlighting from the currently selected row (if any)
	 *
	 * @param index the index of the newly selected row. Must not be null
	 */
	setSelected: function (index) {
		let rowToSelect = document.getElementById('resultsRow_' + index);
		if (rowToSelect) {

			// Reset the style of the currently selected row
			let currentlySelectedRow = document.getElementById('resultsRow_' + this.indexOfSelectedItem);
			if (currentlySelectedRow) {
				currentlySelectedRow.className = 'sirenumRegRowStyling';
			}

			// Set the style of the newly selected row and record the selection
			rowToSelect.className = 'selectedRow';
			this.indexOfSelectedItem = index;
		}
	},

	/**
	 * Updates the Salesforce input using the selected auto-completion result.
	 *
	 * @param input  the primary input field. Must not be null
	 */
	confirmSelection: function (input) {
		if (this.indexOfSelectedItem === -1) {
			let newItemRow = this.getNewItemRow();
			if (newItemRow) {
				newItemRow.click();
			}
		} else if (this.results.length > 0 &&
			(this.indexOfSelectedItem === 0 || this.indexOfSelectedItem) &&
			this.indexOfSelectedItem >= 0 && this.indexOfSelectedItem < this.results.length) {

			let result = this.results[this.indexOfSelectedItem];
			// Take the first column's value (the name), ensure that the entity encoding for an embedded apostrophe is
			// replaced with a plain apostrophe and set this as the input value
			this.setNameValue(input, result.columns[0].replace('&#39;', '\''));
			this.setIdValue(input, result.value);

			input.prevId = input.getAttribute('lookupValue');
			input.prevValue = input.value;
		}
		this.close();
	},

	/**
	 * Set the Id of the selected item.
	 *
	 * @param input the primary input field. Must not be null
	 * @param value the id value to be set.
	 */
	setIdValue: function (input, value) {
		if ((value || input.prevId) && value !== input.prevId) { // If one of the values is not null and they do not match

			// The Salesforce apex:inputField includes some additional hidden inputs to make it work. The following
			// code updates these inputs using the relevant data (when auto-completion is being used with an input field)
			var idInput = document.getElementById(input.getAttribute("id") + "_lkid");
			if (idInput) {
				idInput.value = value;
			}

			var idTarget = input.getAttribute("sirenum-id-target");
			var idTargetInput = !!idTarget ? document.getElementById(idTarget) : null;
			if (idTargetInput) {
				idTargetInput.value = value;
			}

			if (value) {
				input.setAttribute("lookupValue", value);
			} else {
				input.removeAttribute('lookupValue');
			}

			if (input.changeFun) {
				input.changeFun();
			}
		}
	},

	/**
	 * Change the display value of the autocomplete input.
	 *
	 * @param input the primary input field. Must not be null
	 * @param value the name value to be set.
	 */
	setNameValue: function (input, value) {
		input.value = value;

		// The Salesforce apex:inputField includes some additional hidden inputs to make it work. The following
		// code updates these inputs using the relevant data (when auto-completion is being used with an input field)
		var idInput = document.getElementById(input.getAttribute("id") + "_lkold");
		if (idInput) {
			idInput.value = value;
		}
	},

	/**
	 * Handles "keyboard shortcuts" for the auto-completion input.
	 *
	 * @param event the event that could represent a "keyboard shortcut" action. Must not be null
	 * @param elem  the element representing the auto-completion result list against which the shortcut is
	 *              being applied. Must not be null
	 */
	quickSelect: function (event, elem) {
		let isDropdownOpen = this.isDropdownOpen();

		if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
			// Open the dropdown if it is not already open, else scroll through the results
			if (!isDropdownOpen) {
				// open the dropdown
				this.filterChanged(elem);
			} else if (this.results.length > 1) {
				let minimumRowIndex = this.getNewItemRow() ? -1 : 0;
				let newIndex;
				if (event.key === 'ArrowUp') {
					// cursor up moves back towards the start of the list, cycling to the end of the list when used at the start
					if (this.indexOfSelectedItem > minimumRowIndex) {
						newIndex = this.indexOfSelectedItem - 1;
					} else {
						newIndex = this.results.length - 1;
					}
				} else if (event.key === 'ArrowDown') {
					// cursor down moves towards the end of the list, cycling to the start of the list when used at the end
					if (this.indexOfSelectedItem < this.results.length - 1) {
						newIndex = this.indexOfSelectedItem + 1;
					} else {
						newIndex = minimumRowIndex;
					}
				}
				this.setSelected(newIndex);
				let row = document.getElementById("resultsRow_" + newIndex);
				if (row) {
					scrollIntoViewIfNeeded(row);
				}
			}
		} else if ((event.key === 'Enter' || event.key === 'Tab') && isDropdownOpen) {
			// Tab or Enter selects the current result
			stopBubble(event);
			this.confirmSelection(elem);
			if (event.key === 'Enter') {
				stopBubble(event);
				elem.dispatchEvent(new Event("blur"));
			}
		} else if (event.key === 'Escape' && isDropdownOpen) {
			// Escape closes the auto-complete
			stopBubble(event);
			this.close();
			elem.dispatchEvent(new Event("blur"));
		}
	},

	/**
	 * Sets up auto-completion behaviour on the specified Salesforce input, assuming it hasn't already been set up.
	 *
	 * @param elem the input element to be set up with auto-completion behaviour. Must not be null
	 */
	initializeElement: function (elem) {
		if (elem.hasAttribute("autoLookupSetup")) {
			return;
		}

		// Remove standard lookup button
		if (elem.getAttribute("sirenum-autocomplete-lookup") != "true") {
			var btnElem = elem.nextElementSibling;

			while (btnElem) {
				if (btnElem.tagName == "A") {
					break;
				}

				btnElem = btnElem.nextElementSibling;
			}

			if (btnElem) {
				btnElem.style.display = "none";
			}
		}

		var _this = this;
		var handleManualEntry = function (e) {
			if (e.key !== 'Enter') {
				// Remove uninvoked timeout
				if (elem.autoLookupInvokeTimer) {
					clearTimeout(elem.autoLookupInvokeTimer);
					delete elem.autoLookupInvokeTimer;
				}
				// Invoke with a short delay (average typing speed is 3.3 letters per second)
				elem.autoLookupInvokeTimer = setTimeout(function () {
					delete elem.autoLookupInvokeTimer;
					_this.filterChanged(elem);
				}, 350);
			}
		};

		// Perform autocomplete when a character is typed into the input
		elem.addEventListener("keypress", handleManualEntry);

		// Perform autocomplete when text is pasted into the input
		elem.addEventListener("paste", handleManualEntry);

		// Backspace and Delete aren't captured by the keypress event so capture them here to perform autocomplete
		elem.addEventListener("keyup", function () {
			if (event.key === 'Backspace' || event.key === 'Delete') {
				handleManualEntry(event);
			}
		});

		elem.addEventListener("blur", function () {
			// If the user typed a value that matches only one result, but did not then select that result,
			// assume that result was desired and automatically select the result.
			if (_this.results && _this.results.length === 1) {
				_this.confirmSelection(elem);
			}

			setTimeout(function () {
				_this.close();
				_this.checkValue(elem);
				elem.prevId = elem.getAttribute('lookupValue');
				elem.prevValue = elem.value;

				// If no matching name was found by the autocomplete, enable the email field instead.
				var clientContact = mapClientContacts[elem.prevId];
				if (!clientContact) {
					var emailField = document.getElementById("editReq_contactEmail");
					emailField.removeAttribute("disabled");
				}
			}, 300)
		});

		// Reset the results array when focusing on a autocomplete element, so results from other element
		// are not used in this element
		elem.addEventListener("focus", function () {
			_this.results = [];
		});

		elem.addEventListener("keydown", function () {
			_this.quickSelect(event, elem)
		});

		elem.setAttribute("autocomplete", "off");
		elem.setAttribute("autoLookupSetup", "1");
		elem.prevValue = elem.value || "";
		elem.prevId = elem.getAttribute('lookupValue') || '';
	},

	/**
	 * This function is responsible for reverting back to the previously selected value if the lookup
	 * does not allow free text values and the user has typed into the input without selecting
	 * an item from the dropdown.
	 * @param input the autocomplete's controlling input element.
	 */
	checkValue: function (input) {
		if (!input.getAttribute('sirenum-autocomplete-allow-free-text') && !input.getAttribute('lookupValue') && input.value) {
			this.setIdValue(input, input.prevId);
			this.setNameValue(input, input.prevValue);
		}
	},

	/**
	 * Invoke the auto-completion query to retrieve the new results and display in a dropdown.
	 *
	 * @param element the contextual element for the auto-completion. Must not be null
	 */
	filterChanged: function (element) {
		// Clear the id if the value was changed
		if (element.prevValue !== element.value) {
			this.setIdValue(element, null);
		}

		this.fullyLoaded = false;

		this.doQuery(element, function (result, queryVersion) {
			// If another query has already been kicked off then ignore this one.
			if (queryVersion === this.queryVersion) {
				this.redrawDropdown(element, result);
			}
		}.bind(this), ++this.queryVersion);
	},

	/**
	 * Invoke the server to obtain auto-completion matches.
	 *
	 * @param element    the element against which auto-completion was triggered. Will not be null.
	 * @param callback   the callback to be executed once the query results are returned. Must not be null.
	 * @param queryId    a value used to identify this particular query execution when returning results to the callback. Can be null.
	 * @param pageNumber an optional parameter for loading additional matches. Can be null.
	 */
	doQuery: function (element, callback, queryId, pageNumber) {
		if (!this.fullyLoaded) {

			if (pageNumber > 1) {
				this.setInfoText(sirenum_standardLoadingMoreMatches); // This label is rendered in Sirenum_Header.component
			}

			// Send the query text to the server
			let qText = element.value || '';
			let qObj = element.getAttribute("sirenum-autocomplete-object");

			let params = {};

			params.whereClause = element.getAttribute("sirenum-autocomplete-filter");
			if (params.whereClause) {
				params.whereClause = params.whereClause.replace(/\\'/ig, "\'");

				// If the filter contains $Filter.ByGroups then we must send a compressed list
				// of the ids of all objects in the current group selection.
				// Note that we only do this if the function getPropertiesForCachedObject is defined, meaning the
				// invoking element is from the scheduler.
				if (params.whereClause.includes('$Filter.ByGroups') && window.getPropertiesForCachedObject) {
					let cacheData = getPropertiesForCachedObject(qObj);
					let cache = cacheData && cacheData.list;
					if (cache) {
						let inGroupIds =  cache.filter(item => !item.outOfGroup && item.id && item.id !== '*')
							.map(item => item.id);

						params.inGroupIds = prepareIdsForTransmission(inGroupIds);
					}
				}
			}

			params.pageNumber = pageNumber || 1;

			var _this = this;
			Visualforce.remoting.Manager.invokeAction(
				sirenum_autoLookupController,
				qText, qObj, JSON.stringify(params),
				function (result, event) {
					if (event.status) {

						callback(result, queryId);

						if (result.length < 2) { // Less-than 2 because the first result is just column headers
							_this.fullyLoaded = true;

							if (pageNumber > 1) {
								_this.setInfoText(sirenum_standardNoMoreMatches); // This label is rendered in Sirenum_Header.component
							} else {
								_this.setInfoText(sirenum_standardNoMatches); // This label is rendered in Sirenum_Header.component
							}
						}
					}
				},
				{escape: false}
			);
		}
	},

	/**
	 * Gets additional fields for a given object type and where clause.
	 *
	 * @param {string} objectName The sObject name to query. Must not be null.
	 * @param {string} whereClause The where clause to query the object. Must not be null, should include
	 * "sirenum__" namespace prefix.
	 * @param {function} callback A callback function that takes a single result parameter. May be null, but will do
	 * nothing.
	 */
	fetchAdditionalFields: function(objectName, whereClause, callback) {
		Visualforce.remoting.Manager.invokeAction(
			sirenum_autoLookupController,
			'',
			objectName,
			JSON.stringify({whereClause: whereClause}),
			function (result, event) {
				if (callback) {
					callback(result);
				}
			},
			{escape: false}
		);
	},

	/**
	 * Destroys and recreates the dropdown using the auto-completion results.
	 *
	 * @param element the element against which auto-completion was triggered. Will not be null
	 * @param results the auto-completion response details. Will not be null
	 */
	redrawDropdown: function (element, results) {
		try {
			// In order to tunnel the column titles through, these are contained in the first result
			let columnTitles = results[0];
			this.numberOfColumns = columnTitles.columns.length;

			this.results = [];
			this.numPagesLoaded = 0;

			// Remove existing auto-complete list
			this.close();

			// Create the header row
			var headerRow = document.createElement("tr");
			for (let i = 0; i < this.numberOfColumns; i++) {
				let cell = document.createElement("th");
				cell.innerText = columnTitles.columns[i];

				headerRow.appendChild(cell);
			}
			headerRow.className = "sirenumAutoCompleteHeaders";
			var header = document.createElement('thead');
			header.appendChild(headerRow);

			// Create the results table
			var body = document.createElement('tbody');
			var tbl = document.createElement("table");
			tbl.setAttribute('id', 'sirenumAutoCompleteTable');
			tbl.className = "autosearchtable";
			tbl.appendChild(header);
			tbl.appendChild(body);

			if (element.objectConstructorFunction) {
				let newItemRow = document.createElement('tr');
				newItemRow.setAttribute('id', 'resultsRow_-1');
				newItemRow.className = 'sirenumRegRowStyling';
				newItemRow.onclick = e => {
					stopBubble(e);
					element.objectConstructorFunction();
					return false;
				};
				newItemRow.onmousemove = function() {
						this.setSelected(-1);
					}.bind(this);
				body.appendChild(newItemRow);

				let newItemCell = document.createElement('td');
				newItemCell.className = 'sirenumCellStyling';
				newItemCell.setAttribute('colspan', this.numberOfColumns);
				newItemRow.appendChild(newItemCell);

				let newItemIcon = document.createElement('span');
				newItemIcon.className = 'fas fa-plus';
				newItemIcon.style.marginRight = '10px';
				newItemCell.appendChild(newItemIcon);

				let newItemLabel = document.createElement('span');
				newItemLabel.innerText = sirenum_standardNewItem.format(columnTitles.columns[0]); // This label is rendered in Sirenum_Header.component
				newItemCell.appendChild(newItemLabel);
			}

			// Create the dropdown div
			var div = document.createElement("div");
			div.setAttribute("id", "sirenumAutoCompleteDiv");
			div.appendChild(tbl);

			var _this = this;
			div.onscroll = (function (elem, list, res) {
				return function () {
					// If we have scrolled to the bottom of the dropdown then load more items.
					// Note that the doQuery method will ensure only one query is executed at a time and will not
					// requery if there is no more data to retrieve.
					if (list.offsetHeight + list.scrollTop >= list.scrollHeight - 2) {
						_this.loadMore(elem, res);
					}
				}
			})(element, div, results);

			let scrollTop = 0;
			let scrollableParent = getScrollParent(element);
			if (scrollableParent) {
				// Since the selection list is position: fixed, we must hide it when the parent scrolls
				scrollableParent.addEventListener('scroll', this.close);

				// The dropdown position needs to take into account any scrolling, only if the closest scrollable
				// parent is a child of the element's offsetParent, or if they are the same.
				if (scrollableParent === element.offsetParent ||
					scrollableParent.offsetParent === element.offsetParent) {
					scrollTop = scrollableParent.scrollTop;
				}
			}

			// Determine the dimensions of the dropdown.
			let rect = element.getBoundingClientRect();
			div.style.minWidth = (rect.width) + "px";
			div.style.left = element.offsetLeft + 'px';
			let maxHeight;
			if (rect.bottom < window.innerHeight * 0.7) {
				div.style.top = element.offsetTop + rect.height - scrollTop + "px";
				maxHeight = (window.innerHeight - rect.bottom - 20);
			} else {
				div.style.bottom = element.offsetParent.clientHeight - element.offsetTop + scrollTop + 'px';
				maxHeight = (rect.top - 20);
			}
			// If the user has a screen big enough to show all 25 initial results at once (25 items * 25px = 625px)
			// then make sure the dropdown is not big enough to do the same. The loading of additional items is done
			// on scroll so there always needs to be somewhere to scroll to.
			div.style.maxHeight = Math.min(maxHeight, 600) + 'px';

			element.parentNode.insertBefore(div, element);

			// Add the first page of items to the dropdown
			this.addRowsToDropdown(element, results);

			// Now that the div is in the page and we can check position, ensure it does not render outside the window
			if (div.getBoundingClientRect().right + 1 > document.body.clientWidth) {
				div.style.left = '';
				div.style.right = '1px';
			}
			// Lock the current width so that the autocomplete does not resize when new rows are added.
			div.style.maxWidth = div.clientWidth + 'px';

			// If there are no results (if results.length is less than 2 - because the first item is just a list of
			// column headers) but there is a new item button then the new item button should be selected,
			// otherwise the first result (or nothing) should be selected
			if (results.length < 2 && this.getNewItemRow()) {
				this.indexOfSelectedItem = -1;
			} else {
				this.indexOfSelectedItem = 0;
			}
			this.setSelected(this.indexOfSelectedItem);

		} catch (ex) {
			console.debug(ex);
		}
	},

	/**
	 * Adds rows from auto-completion results to the dropdown.
	 * Requires the dropdown to have already been created and prepared.
	 *
	 * @param input       the input element against which auto-completion was triggered. Will not be null
	 * @param results     the auto-completion response details. Will not be null
	 */
	addRowsToDropdown: function (input, results) {
		var _this = this;
		var resultList = document.getElementById('sirenumAutoCompleteTable').getElementsByTagName('tbody')[0];

		//Column titles are in the first result. We want the data which is in the remainder of the array
		var newResults = results.slice(1);
		var indexOfFirstNewResult = this.results.length;
		this.results = this.results.concat(newResults);
		this.numPagesLoaded++;

		// Remove the info message
		this.setInfoText(null);

		var result, i;
		// Create tabular list with auto complete results
		for (i = 0; i < newResults.length; i++) {
			result = newResults[i];
			var rowIndex = i + indexOfFirstNewResult;

			var row = document.createElement("tr");
			row.className = "sirenumRegRowStyling";

			row.onclick = (function(inp, idx) {
				return function() {
					_this.setSelected(idx);
					_this.confirmSelection(inp);
				};
			})(input, rowIndex);

			row.onmousemove = (function(idx) {
				return function() {
					_this.setSelected(idx);
				};
			})(rowIndex);

			row.setAttribute("id", "resultsRow_" + rowIndex);

			for (var j = 0; j < result.columns.length; j++) {
				var cell = document.createElement("td");
				cell.innerText = result.columns[j];
				cell.className = "sirenumCellStyling";
				row.appendChild(cell);
			}

			// Invoke item render callback on the first cell
			if (input.onItemRender) {
				input.onItemRender(row.firstChild, result);
			}

			resultList.appendChild(row);
		}
	},

	/**
	 * Loads another page of results and adds them to the dropdown.
	 *
	 * @param element the input element against which auto-completion was triggered. Must not be null
	 */
	loadMore: function (element) {
		var _this = this;
		this.doQuery(element, function (results) {
			_this.addRowsToDropdown(element, results);
		}, null, this.numPagesLoaded + 1);
	},

	/**
	 * Adds a non-selectable row to the bottom of the result list to show the provided message, or changes the message
	 * if it already exists. The row will be removed if the message value is null.
	 *
	 * @param infoText the message to show. Null values will cause the message row to be removed.
	 */
	setInfoText: function (infoText) {
		var infoMsg = document.getElementById('sirenumAutoCompleteInfoMsg');

		if (infoText && window.renderElement) {
			if (!infoMsg) {
				infoMsg = renderElement({
					e: 'td#sirenumAutoCompleteInfoMsg.sirenumCellStyling',
					colspan: this.numberOfColumns
				});

				let infoRow = renderElement({e: 'tr.sirenumRegRowStyling'});
				infoRow.appendChild(infoMsg);

				document.getElementById('sirenumAutoCompleteTable').getElementsByTagName('tbody')[0]
					.appendChild(infoRow);
			}
			infoMsg.innerText = infoText;
		} else if (infoMsg) {
			infoMsg.parentNode.removeChild(infoMsg);
		} else {
			console.log(infoText);
		}
	},

	/**
	 * Gets the new item row if it exists.
	 *
	 * @returns {HTMLElement | null} the new item row. Can be null.
	 */
	getNewItemRow: function () {
		return document.getElementById('resultsRow_-1');
	}
};

/**
 * This function is called to bind auto-completion to those inputs in the page that include the required
 * custom attribute ("sirenum-autocomplete-object").
 */
function sirenumAutoCompleteInitialize() {
    var inputs = document.getElementsByTagName("input");

	for (var i = 0; i < inputs.length; i++) {
		if (inputs[i].hasAttribute("sirenum-autocomplete-object")) {
			SirenumAutoComplete.initializeElement(inputs[i]);
		}
	}
}

/**
 * Opens a URL in a new tab using a hidden HTML anchor tag to ensure it is opened
 * in the correct SF experience (Classic or Lightning)
 *
 * @param {string} url the URL to open in a new tab. Must not be null
 */
function openUrlInNewTab(url) {
	// Create anchor tag to open url. Anchor tag is needed so the URL is opened
	// in the correct SF experience (Classic or Lightning)
	const anchorToUrl = document.createElement('a');
	anchorToUrl.target = "_blank";
	anchorToUrl.href = url;
	anchorToUrl.style.display = "none";
	// Insert it into the DOM
	document.body.appendChild(anchorToUrl);
	// Activate it injecting a click
	anchorToUrl.click();
	// Delete if from the DOM
	anchorToUrl.parentNode.removeChild(anchorToUrl);
}

// Explicitly invoke the initialization to bind the auto-completion functionality to those inputs in the
// page that are appropriately marked with a custom attribute.
window.addEventListener('load', sirenumAutoCompleteInitialize, false);