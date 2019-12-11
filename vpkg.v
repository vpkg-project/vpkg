module main

import (
    api as vpkg
    os
)

fn main() {
    _args := os.args
    mut app := vpkg.new(os.getwd())
    
    app.run(_args[1.._args.len])
}
