module main

import api as vpkg
import os

fn main() {
    args := os.args
    mut app := vpkg.new(os.getwd())
    
    app.run(args[1..])
}
