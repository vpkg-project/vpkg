module main

import (
    api
    os
)

fn main() {
    _args := os.args
    mut app := api.new_vpkg(os.getwd())
    
    app.run(_args.slice(1, _args.len))
}
