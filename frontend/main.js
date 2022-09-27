var ledStripControl = (function() {
	"use strict";

	var HOST = "";

	var segments = null;
	var activeSegmentId = null;
	var us = null;

	var sendingKeystrokes = false;

	var lastSelectedId = null;
	var lastSeenLogId = -1;
	var allowedToUpdate = true;

	var editor = null;

	function xhr(url, method, data, callback) {
		var oReq = new XMLHttpRequest();

		if (callback) {
			function reqListener() {
				var json = null;
				try { json = JSON.parse(this.responseText); } catch(e) {}
				callback(json);
			}
			oReq.addEventListener("load", reqListener);
		}

		oReq.open(method, url);
		oReq.send(data);
	}

	function getJson(url, callback) {
		xhr(url, "GET", "", callback);
	}
	function putJson(url, data, callback) {
		xhr(url, "PUT", JSON.stringify(data), callback);
	}

	function updateUs() {
		us = document.getElementById("us").value;
		showSegments();
	}
	updateUs();

	function saveAndShowSegments(segs) {
		segments = {};
		for (var i in segs) {
			segments[segs[i].id] = segs[i];
		}
		showSegments();
	}

	function fetchSegments() {
		getJson(HOST + "/api/segments.json", saveAndShowSegments);
	}

	function activateSegment(segment) {
		activeSegmentId = segment.id;
		getJson(HOST + "/api/segments.json", saveAndShowSegments);
		showSegments();
		document.getElementById("segment-control").style.display = "block";
	}

	function repeatString(text, amount) {
		var result = "";
		for (var i = 0; i < amount; i++) {
			result += text;
		}
		return result;
	}

	function showSegmentEventListener(e) {
		if (e.currentTarget.dataset["segment"] !== "true") return;

		var id = e.currentTarget.dataset["id"];
		activateSegment(segments[id]);
		e.stopPropagation();
	}
	function showOwnerEventListener(e) {
		if (e.currentTarget.dataset["segment"] !== "true") return;

		var owner = e.currentTarget.dataset["owner"];
		if (owner) {
			document.getElementById("owner_label").innerText = owner;
		} else {
			document.getElementById("owner_label").innerHTML = "<i>vrij</i>";
		}
		document.getElementById("owner_label").style.display = "block";
		document.getElementById("owner_label").style.left = (e.currentTarget.clientWidth/2 + e.currentTarget.offsetLeft - document.getElementById("owner_label").clientWidth/2) + "px";
		document.getElementById("owner_label").style.top = (e.currentTarget.offsetTop - document.getElementById("owner_label").clientHeight - 2) + "px";
		e.stopPropagation();
	}
	function hideOwnerEventListener(e) {
		if (e.currentTarget.dataset["segment"] !== "true") return;

		document.getElementById("owner_label").innerHTML = "";
		document.getElementById("owner_label").style.display = "none";
	}

	function updatePublishButton() {
		var activeSegment = activeSegmentId !== null ? segments[activeSegmentId] : null;
		if (editor && editor.getModel().getValue() == activeSegment.code) {
			document.getElementById("publish-button").innerText = "Gepubliceerd";
			document.getElementById("publish-button").setAttribute("disabled", "disabled");
		} else {
			document.getElementById("publish-button").innerText = "Publiceer";
			document.getElementById("publish-button").removeAttribute("disabled");
		}
	}

	function updateLogs() {
		if (!allowedToUpdate || activeSegmentId == null) {
			return;
		}
		allowedToUpdate = false;
		if (lastSelectedId != activeSegmentId) {
			lastSelectedId = activeSegmentId;
			lastSeenLogId = -1;
			document.getElementById("logs").value = '';
		}
		const controller = new AbortController()
		setTimeout(() => {controller.abort(); allowedToUpdate = true}, 3000);

		// API data looks like this:
		// {'0': "line 0", '1': "line 1"}
		fetch(HOST + '/api/logs/' + activeSegmentId + '.json')
	  .then(response => response.json())
	  .then(data => {
			let minimal_key = Object.keys(data).reduce((a, b) => Number(a) < Number(b) ? a : b);
			if (minimal_key < lastSeenLogId + 1) {
				minimal_key = lastSeenLogId + 1;
			}
			var node = document.getElementById("logs");
			while (minimal_key in data) {
				node.value += data[minimal_key];
				lastSeenLogId = minimal_key;
				minimal_key++;
			}
			allowedToUpdate = true;
		});
	}

	function showSegments() {
		var segmentsContainer = document.getElementById("segments");
		segmentsContainer.innerHTML = "";

		var prevSegEnd = 0;
		if (segments !== null) for (var i in segments) {
			if (!segments.hasOwnProperty(i)) continue;
			var seg = segments[i];
			var color = seg.owner === "" ? "#555" : seg.owner === us ? "#050" : "#700";

			var unsegmented = parseFloat(seg.begin) - prevSegEnd;
			if (unsegmented > 0) {
				var unsegmented_el = document.createElement("span");
				unsegmented_el.className = "unsegmented";
				unsegmented_el.innerHTML = repeatString("<span class='led'></span>", unsegmented);
				segmentsContainer.append(unsegmented_el);
			}

			var rect = document.createElement("a");
			rect.className = seg.id === activeSegmentId ? "active segment" : "segment";
			rect.style.backgroundColor = color;
			rect.id = "segment" + seg.id;
			rect.href = "#segment" + seg.id;
			rect.dataset["segment"] = "true";
			rect.dataset["owner"] = seg.owner;
			rect.dataset["id"] = seg.id;
			rect.addEventListener("click", showSegmentEventListener);
			rect.addEventListener("focus", showOwnerEventListener);
			rect.addEventListener("blur", hideOwnerEventListener);
			rect.addEventListener("mouseover", showOwnerEventListener);
			rect.addEventListener("mouseout", hideOwnerEventListener);
			rect.innerHTML = repeatString("<span class='led'></span>", seg.length);
			segmentsContainer.appendChild(rect);

			prevSegEnd = seg.begin + seg.length;
		}

		var activeSegment = activeSegmentId !== null ? segments[activeSegmentId] : null;
		if (activeSegment !== null) {
			document.getElementById("active_segment_id").innerText = activeSegmentId;
			document.getElementById("active_segment_begin").innerText = activeSegment.begin;
			document.getElementById("active_segment_end").innerText = activeSegment.begin + activeSegment.length - 1;

			updatePublishButton();

			if (!editor) {
				require(["vs/editor/editor.main"], () => {
					if (editor) return;
					monaco.languages.registerCompletionItemProvider('lua', {
						provideCompletionItems: function (model, position) {
							var word = model.getWordUntilPosition(position);
							var range = {
								startLineNumber: position.lineNumber,
								endLineNumber: position.lineNumber,
								startColumn: word.startColumn,
								endColumn: word.endColumn
							};
							return {
								suggestions: createDependencyProposals(range)
							};
						}
					})
					editor = monaco.editor.create(document.getElementById('lua_editor'), {
						value: activeSegment.code,
						language: 'lua',
						theme: 'vs-dark',
						readOnly: activeSegment ? !(activeSegment.owner !== "" && activeSegment.owner === us) : true
					});
				});
			} else if (activeSegment) {
				editor.getModel().setValue(activeSegment.code)
			}

			if (activeSegment.owner !== "" && activeSegment.owner === us) {
				document.getElementById("release_button").style.display = "";
				document.getElementById("release_button").innerText = "Onteigen";
				document.getElementById("release_button").removeAttribute("disabled");

				if (editor) {
					editor.updateOptions({
						readOnly: false 
					})
				}
				document.getElementById("not-your-own").style.display = "none";
				document.getElementById("program-controls").style.display = "block";
				document.getElementById("program-instructions").style.display = "block";
			} else {
				document.getElementById("release_button").style.display = "none";

				if (editor) {
					editor.updateOptions({
						readOnly: true
					})
				}
				document.getElementById("not-your-own").style.display = "block";
				document.getElementById("program-controls").style.display = "none";
				document.getElementById("program-instructions").style.display = "none";
				document.getElementById("keystrokes-checkbox").checked = false;
			}

			if (activeSegment.owner !== "") {
				document.getElementById("active_segment_owner").innerText = activeSegment.owner;
				document.getElementById("claim_button").style.display = "none";

				document.getElementById("program").style.display = "block";
			} else {
				document.getElementById("active_segment_owner").innerText = "nog niemand";
				document.getElementById("claim_button").style.display = "";
				document.getElementById("claim_button").innerText = "Eigen je toe";
				document.getElementById("claim_button").removeAttribute("disabled");

				document.getElementById("program").style.display = "none";
			}
		}
	}


	function createDependencyProposals(range) {
		return [
			{
				label: 'led',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Stel led op led_nr in op de kleur met gegeven RGB-waarden (0-255)',
				insertText: 'led(${1:led_nr}, ${2:r}, ${3:g}, ${4:b})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
			{
				label: 'ledamount',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Retourneert het aantal leds',
				insertText: 'ledamount()',
				range: range
			},
			{
				label: 'delay',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Wachten voor een gedurend aantal ms',
				insertText: 'delay(${1:ms})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
			{
				label: 'waitframes',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Wachten voor een gedurend aantal frames',
				insertText: 'delay(${1:frames})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
			{
				label: 'print',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Stuur message naar de console',
				insertText: 'print(${1:msg})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
			{
				label: 'subscribe',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Subscribe op de berichten van het gespecifieerde topic. Topic is een string',
				insertText: 'subscribe(${1:topic})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
			{
				label: 'unsubscribe',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Unsubscribe op de berichten van het gespecifieerde topic. Topic is een string',
				insertText: 'subscribe(${1:topic})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
			{
				label: 'getmessage',
				kind: monaco.languages.CompletionItemKind.Function,
				documentation: 'Dit geeft, indien er een bericht met een bepaalde topic is en je subscribed bent, het bericht terug, anders nil. Je kan berichten sturen door bvb met HTTPie http PUT 10.0.0.10/api/mailbox.json message="hello there" topic="hellomsg" uit te voeren',
				insertText: 'getmessage(${1:topic})',
				insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
				range: range
			},
		];
	}

	document.getElementById("claim_button").addEventListener("click", function () {
		document.getElementById("claim_button").innerText = "Bezig met toe-eigenen...";
		document.getElementById("claim_button").setAttribute("disabled", "disabled");
		var activeSegment = segments[activeSegmentId];
		if (!activeSegment) { throw new Error("Trying to claim segment but no segment active"); }
		putJson(HOST + "/api/code.json", {
			"id": activeSegmentId,
			"owner": us,
			"code": activeSegment.code,
			"languageid": "lua"
		}, fetchSegments);
	});

	document.getElementById("release_button").addEventListener("click", function() {
		document.getElementById("release_button").innerText = "Bezig met onteigenen...";
		document.getElementById("release_button").setAttribute("disabled", "disabled");
		var activeSegment = segments[activeSegmentId];
		if (!activeSegment) { throw new Error("Trying to release segment but no segment active"); }
		putJson(HOST + "/api/code.json", {
			"id": activeSegmentId,
			"owner": "",
			"code": activeSegment.code,
			"languageid": "lua"
		}, fetchSegments);
	});

	document.getElementById("publish-button").addEventListener("click", function() {
		document.getElementById("publish-button").innerText = "Bezig met publiceren...";
		document.getElementById("publish-button").setAttribute("disabled", "disabled");
		var activeSegment = segments[activeSegmentId];
		if (!activeSegment) { throw new Error("Trying to update code of segment but no segment active"); }
		putJson(HOST + "/api/code.json", {
			"id": activeSegmentId,
			"owner": activeSegment.owner,
			"code": editor ? editor.getModel().getValue() : '',
			"languageid": "lua"
		}, fetchSegments);
	});

	document.getElementById("keystrokes-checkbox").addEventListener('change', function(event) {
		sendingKeystrokes = event.currentTarget.checked;
	});

	document.getElementById("lua_editor").addEventListener("keyup", updatePublishButton);
	document.getElementById("lua_editor").addEventListener("change", updatePublishButton);

	fetchSegments();
	setInterval(updateLogs, 1000);

  window.addEventListener('keydown', function(e) {
		if (sendingKeystrokes) {
			putJson(HOST + "/api/mailbox.json", {'topic': 'keystroke.' + activeSegmentId, 'message': `KEYDOWN ${e.keyCode} ignoreme ignoreme`}, function() {});
		}
	});
	return {
		updateUs: updateUs,
	};
})();
