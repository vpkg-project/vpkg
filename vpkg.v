module main

import api as vpkg
import os

fn main() {
    args := os.args.clone()
    mut app := vpkg.new(os.getwd())
    
    app.run(args[1..])
}
