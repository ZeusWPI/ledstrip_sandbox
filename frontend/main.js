var ledStripControl = (function() {
	"use strict";

	var HOST = "";

	var segments = null;
	var activeSegmentId = null;
	var us = null;

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
		if (document.getElementById("lua_editor").value == activeSegment.code) {
			document.getElementById("publish-button").innerText = "Gepubliceerd";
			document.getElementById("publish-button").setAttribute("disabled", "disabled");
		} else {
			document.getElementById("publish-button").innerText = "Publiceer";
			document.getElementById("publish-button").removeAttribute("disabled");
		}
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

			document.getElementById("lua_editor").value = activeSegment.code;

			if (activeSegment.owner !== "" && activeSegment.owner === us) {
				document.getElementById("release_button").style.display = "";
				document.getElementById("release_button").innerText = "Onteigen";
				document.getElementById("release_button").removeAttribute("disabled");

				document.getElementById("lua_editor").removeAttribute("disabled");
				document.getElementById("not-your-own").style.display = "none";
				document.getElementById("program-controls").style.display = "block";
				document.getElementById("program-instructions").style.display = "block";
			} else {
				document.getElementById("release_button").style.display = "none";

				document.getElementById("lua_editor").setAttribute("disabled", "disabled");
				document.getElementById("not-your-own").style.display = "block";
				document.getElementById("program-controls").style.display = "none";
				document.getElementById("program-instructions").style.display = "none";
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

	document.getElementById("claim_button").addEventListener("click", function() {
		document.getElementById("claim_button").innerText = "Bezig met toe-eigenen...";
		document.getElementById("claim_button").setAttribute("disabled", "disabled");
		var activeSegment = segments[activeSegmentId];
		if (!activeSegment) { throw new Error("Trying to claim segment but no segment active"); }
		putJson(HOST + "/api/code.json", {
			"id": activeSegmentId,
			"owner": us,
			"code": activeSegment.code
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
			"code": activeSegment.code
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
			"code": document.getElementById("lua_editor").value
		}, fetchSegments);
	});

	document.getElementById("lua_editor").addEventListener("keyup", updatePublishButton);
	document.getElementById("lua_editor").addEventListener("change", updatePublishButton);

	fetchSegments();

	return {
		updateUs: updateUs,
	};
})();
