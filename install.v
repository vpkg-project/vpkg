import api
import os

fn main() {
	mut inst := api.new_vpkg('.')
	inst.run(['install'])

	os.system('rm ${os.executable()}')
}