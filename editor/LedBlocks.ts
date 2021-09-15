import Blockly from "blockly";
import lua from "blockly/lua"

export default class LedBlocks {

    static AddBlocks() {

        this.add_delay_block()
        this.add_waitframes_block()
        this.add_wled_block()
        this.add_led_amount();
    }
    private static add_wled_block() {
        const delay_json = {
            "type": "led",
            "message0": "%1 %2 %3 %4 %5",
            "previousStatement": null,
            "nextStatement": null,
            "args0": [
                {
                    "type": "field_label_serializable",
                    "name": "NAME",
                    "text": "led"
                },
                {
                    "type": "input_value",
                    "name": "index",
                    "check": "Number"
                },
                {
                    "type": "input_value",
                    "name": "red",
                    "check": "Number"
                },
                {
                    "type": "input_value",
                    "name": "green",
                    "check": "Number"
                },
                {
                    "type": "input_value",
                    "name": "blue",
                    "check": "Number"
                }
            ],
            "colour": 345,
            "tooltip": "Sets the led at index 'index' to the specified RGB-value ",
            "helpUrl": ""
        }

        Blockly.Blocks['led'] = {
            init: function () {
                this.jsonInit(delay_json);
            }
        };

        lua['led'] = function (block) {
            const value = lua.valueToCode(block, 'index', lua["ORDER_ATOMIC"]);
            const r = lua.valueToCode(block, 'red', lua["ORDER_ATOMIC"]);
            const g = lua.valueToCode(block, 'green', lua["ORDER_ATOMIC"]);
            const b = lua.valueToCode(block, 'blue', lua["ORDER_ATOMIC"]);
            return `led(${value},${r},${g},${b})
`;
        };

    }
    
    private static add_waitframes_block() {
        const delay_json = {
            "type": "waitframes",
            "previousStatement": null,
            "nextStatement": null,
            "message0": "%1 %2",
            "args0": [
                {
                    "type": "field_label_serializable",
                    "name": "NAME",
                    "text": "waitframes"
                },
                {
                    "type": "input_value",
                    "name": "framewait",
                    "check": "Number"
                }
            ],
            "colour": 345,
            "tooltip": "Waits the given amount of frames",
            "helpUrl": ""
        }

        Blockly.Blocks['waitframes'] = {
            init: function () {
                this.jsonInit(delay_json);
            }
        };

        lua['waitframes'] = function (block) {
            // @ts-ignore
            const value = lua.valueToCode(block, 'framewait', lua.ORDER_ATOMIC);
            return 'waitframes(' + value + ')\n';
        };

    }
    
    private static add_led_amount(){
       const def = {
            "type": "ledamount",
           "message0": "%1",
           "args0": [
               {
                   "type": "field_label_serializable",
                   "name": "NAME",
                   "text": "ledamount in strip"
               }],
            "output": null,
            "colour": 345,
            "tooltip": "Gives the number of leds in the ledstrip",
            "helpUrl": ""
        }

        Blockly.Blocks['ledamount'] = {
            init: function () {
                this.jsonInit(def);
            }
        };
        
       lua['ledamount'] = function(block) {
            // @ts-ignore
           return ["ledamount()", lua.ORDER_NONE];
        };
    }

    private static add_delay_block() {
        const delay_json = {
            "type": "delay",
            "message0": "%1 %2",
            "previousStatement": null,
            "nextStatement": null,
            "args0": [
                {
                    "type": "field_label_serializable",
                    "name": "NAME",
                    "text": "delay (ms)"
                },
                {
                    "type": "input_value",
                    "name": "wait_time_millisecs",
                    "check": "Number"
                }
            ],
            "colour": 345,
            "tooltip": "Waits the given amount of time in milliseconds",
            "helpUrl": ""
        }

        Blockly.Blocks['delay'] = {
            init: function () {
                this.jsonInit(delay_json);
            }
        };

        lua['delay'] = function (block) {
            // @ts-ignore
            const value = lua.valueToCode(block, 'wait_time_millisecs', lua.ORDER_ATOMIC);
            return 'delay(' + value + ')\n';
        };

    }

}