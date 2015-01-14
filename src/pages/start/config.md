## Configuring SBT



### The Relationship Between Play and SBT

Play consists of two components: *a set of libraries* used by our application at runtime, and *an SBT plugin* that augments SBT's default behaviour with custom commands and behaviours.

Because Play is only a plugin for SBT, we can compile Play projects using any of the flavours of SBT above. Each project must contain two configuration files, one specifying the version of SBT to use, and the other listing Play as a plugin dependency. Once we've set this up, SBT will contain all of the commands we need to build and run Play code. We will discuss the various configuration files and their contents later this chapter.
