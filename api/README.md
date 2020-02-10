# Module files details

The following is an explanation of the files in this module:

- `manifest.v` - api's for reading/regenerating/writing manifest files (vpkg.json and v.mod)
- `methods.v` - abstraction layer and api for implementing various fetching methods like git,mercurial, hg, and svn. (http soon :slight_smile: )
- `sources.v` - this is where you implement the functions for fetching metadata from package  managers like vpkg registry and vpm
- `utils.v` - utilities functions
- `vargs.v` - local copy of vargs just to avoid cloning the dependency.
- `vmod.v` - v.mod scanner and tokenizer
