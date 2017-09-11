/--
 --  Script to combine all three.fun source files into a single file
 --  called three.fun
 --/

script build_fun {

    public main(args[]) {
        file[] files = file("../src/").files
        file three_file = file("three.fun"); 

        keep: fun_source = ""
        keep as fun_source: dynamic add_to_fun_source(text) = fun_source + text + newline

                                                      
        "Rebuilding three.fun...";
        newline;

        for file f in files {
            if (ends_with(f.name, ".fun")) {
                f.name;
                newline;
                eval(add_to_fun_source(f.contents));
            } else {
                "Skipping ";
                f.name;
                newline;
            }
        }

        if (!three_file.overwrite(fun_source)) {
            "  ...unable to write to ";
            three_file.name;
            newline;
        }

        "Done.";
        newline;
        exit(0);
    }
}

