import Blockly from 'blockly';
import lua from 'blockly/lua';
import Utils from "./Utils";
import LedBlocks from "./LedBlocks";

const toolbox = document.getElementById('toolbox')
console.log(toolbox)


const workspace = Blockly.inject('blockly',
    {toolbox: toolbox});

LedBlocks.AddBlocks()

const fromLocalStorage = localStorage.getItem("code")
if (fromLocalStorage !== null) {
    Blockly.Xml.domToWorkspace(Blockly.Xml.textToDom(fromLocalStorage), workspace);
}

function myUpdateFunction(event) {
    const xml_text = Blockly.Xml.domToText(Blockly.Xml.workspaceToDom(workspace));
    localStorage.setItem("code", xml_text)
}

workspace.addChangeListener(myUpdateFunction);

document.getElementById("export")
    .onclick = (e => {
    var code = lua.workspaceToCode(workspace);
    Utils.offerContentsAsDownloadableFile(code, "ledstrip_code.lua", {
        mimetype: "application/x-lua"
    })
})

document.getElementById("export-blocky")
    .onclick = (e => {
    var xml = Blockly.Xml.workspaceToDom(workspace);
    var xml_text = Blockly.Xml.domToText(xml);
    Utils.offerContentsAsDownloadableFile(xml_text, "ledstrip_code.xml", {
        mimetype: "application/xml"
    })
})

const fileInput = document.getElementById('load');
fileInput.onchange = () => {
    const selectedFiles = [...fileInput.files];
    var reader = new FileReader();
    reader.onload = function (event) {
        try {
            // @ts-ignore
            const xml : string = event.target.result;
            Blockly.Xml.domToWorkspace(Blockly.Xml.textToDom(xml), workspace);
        } catch (e) {
            alert("Invalid blocky file: ", e)
        }
    }
    reader.readAsText(selectedFiles[0])
}