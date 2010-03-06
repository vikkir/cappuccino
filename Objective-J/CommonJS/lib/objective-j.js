
var FILE = require("file");
var window = exports.window = require("browser/window");

if (system.engine === "rhino")
{
    window.__parent__ = null;
    window.__proto__ = global;
}

// setup OBJJ_HOME, OBJJ_INCLUDE_PATHS, etc
window.OBJJ_HOME = exports.OBJJ_HOME = FILE.resolve(module.path, "..");

var frameworksPath = FILE.resolve(window.OBJJ_HOME, "Frameworks/");

var OBJJ_INCLUDE_PATHS = global.OBJJ_INCLUDE_PATHS = exports.OBJJ_INCLUDE_PATHS = [frameworksPath];

#include "Includes.js"

// Find all narwhal packages with Objective-J frameworks.
exports.objj_frameworks = [];
exports.objj_debug_frameworks = [];

var catalog = require("packages").catalog;
for (var name in catalog)
{
    if (!catalog.hasOwnProperty(name))
        continue;

    var info = catalog[name];
    if (!info)
        continue;

    var frameworks = info["objj-frameworks"];
    if (frameworks) {
        if (!Array.isArray(frameworks))
            frameworks = [String(frameworks)];

        exports.objj_frameworks.push.apply(exports.objj_frameworks, frameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }

    var debugFrameworks = info["objj-debug-frameworks"];
    if (debugFrameworks) {
        if (!Array.isArray(debugFrameworks))
            debugFrameworks = [String(debugFrameworks)];

        exports.objj_debug_frameworks.push.apply(exports.objj_debug_frameworks, debugFrameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }
}

// push to the front of the array lowest priority first.
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_frameworks);
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_debug_frameworks);

if (system.env["OBJJ_INCLUDE_PATHS"])
    OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, system.env["OBJJ_INCLUDE_PATHS"].split(":"));

// bring the "window" object into scope.
// TODO: somehow make window object the top scope?
with (window)
{
// runs the objj repl or file provided in args
exports.run = function(args)
{
    if (args)
    {
        // we expect args to be in the format:
        //  1) "objj" path
        //  2) optional "-I" args
        //  3) real or "virtual" main.j
        //  4) optional program arguments

        // copy the args since we're going to modify them
        var argv = args.slice(1);

        while (argv.length && argv[0].indexOf('-I') === 0)
            OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, argv.shift().substr(2).split(':'));
    }

    if (argv && argv.length > 0)
    {
        var arg0 = argv.shift();
        var mainFilePath = FILE.canonical(arg0);

        exports.make_narwhal_factory(mainFilePath)(require, { }, module, system, print, window);

        if (typeof main === "function")
            main([arg0].concat(argv));

        require("browser/timeout").serviceTimeouts();
    }
    else
    {
        exports.repl();
    }
}

exports.repl = function()
{
    var READLINE = require("readline");

    var historyPath = FILE.path(system.env["HOME"], ".objj_history");
    var historyFile = null;

    if (historyPath.exists() && READLINE.addHistory) {
        historyPath.read({ charset : "UTF-8" }).split("\n").forEach(function(line) {
            if (line.trim())
                READLINE.addHistory(line);
        });
    }

    try {
        historyFile = historyPath.open("a", { charset : "UTF-8" });
    } catch (e) {
        system.stderr.print("Warning: Can't open history file '"+historyFile+"' for writing.");
    }

    while (true)
    {
        try {
            system.stdout.write("objj> ").flush();

            var line = READLINE.readline();
            if (line && historyFile)
                historyFile.write(line).write("\n").flush();

            var result = exports.objj_eval(line);
            if (result !== undefined)
                print(result);

        } catch (e) {
            print(e);
        }

        require("browser/timeout").serviceTimeouts();
    }
}

exports.objj_eval = function(/*String*/ aString)
{
    // We need this while code still refers to window.
    Executable.setCommonJSArguments(require, exports, module, system, print, window);

    var executable = exports.preprocess(aString, "", 0);

    if (!executable.hasLoadedFileDependencies())
        executable.loadFileDependencies();

    // A bit of a hack. Executable compiles the code itself into a function, but we want
    // the raw code to eval here.
    var code = executable._code;

    // Not clear why these should be global, varing them doesn't seem to take effect with evaluateString.
    global.objj_executeFile = Executable.fileExecuterForURL(FILE.cwd());
    global.objj_importFile = Executable.fileImporterForURL(FILE.cwd());

    if (typeof system !== "undefined" && system.engine === "rhino")
        return Packages.org.mozilla.javascript.Context.getCurrentContext().evaluateString(global, code, "objj_eval", 0, NULL);

    return eval(code);
}

Executable.setCommonJSParameters("require", "exports", "module", "system", "print", "window");

// creates a narwhal factory function in the objj module scope
exports.make_narwhal_factory = function(path)
{
    return function(require, exports, module, system, print)
    {
        Executable.setCommonJSArguments(require, exports, module, system, print, window);

        Executable.fileImporterForURL(FILE.dirname(path))(path, YES, function()
        {
            print("all done");
        });
    }
}

} // end "with"

if (require.main == module.id)
    exports.run(system.args);
