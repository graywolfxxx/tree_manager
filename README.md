## Programming Assignment

Your task is to write a web based application that allows the user to view an existing, initially empty,
tree and add nodes to it. Tree nodes should be stored in the MySQL database. Thus, your program should be able
to read them from the database to display the tree, and add new nodes to the tree upon user request.
Each node should be identified by a unique node ID and have a parent P.

Please consult the following UI sketch (feel free to make improvements).

```
                                      Tree Manager

Current Tree

Depth                                   Tree Nodes

                                     ┌───────────────┐
  0                                  │ P: None ID: 1 │
                                     └───────┬───────┘
                       ┌─────────────────────┴───────────────────────────┐
                ┌──────┴─────┐                                    ┌──────┴─────┐
  1             │ P: 1 ID: 2 │                                    │ P: 1 ID: 3 │
                └──────┬─────┘                                    └──────┬─────┘
               ┌───────┴─────────────┐                                   │
        ┌──────┴─────┐        ┌──────┴─────┐                      ┌──────┴─────┐
  2     │ P: 2 ID: 4 │        │ P: 2 ID: 5 │                      │ P: 3 ID: 6 │
        └────────────┘        └──────┬─────┘                      └──────┬─────┘
               ┌─────────────┬───────┴─────┬─────────────┐               │
        ┌──────┴─────┐┌──────┴─────┐┌──────┴─────┐┌──────┴──────┐ ┌──────┴──────┐
  3     │ P: 5 ID: 7 ││ P: 5 ID: 8 ││ P: 5 ID: 9 ││ P: 5 ID: 10 │ │ P: 6 ID: 11 │
        └────────────┘└────────────┘└────────────┘└─────────────┘ └─────────────┘

             ┌─────────────────┐
Add Node To: │ PID             │
             └─────────────────┘

╔═══════╗
║  Add  ║
╚═══════╝
```

Typing in parent node ID in **PID** box and clicking **Add** button should add a new node to the node
with that ID or produce and an error message in case invalid node ID is entered. Error message should be
displayed immediately above **Add** button.

We are looking for re-usable code. You are strongly encouraged to "over engineer" this in order to show off
your software architecture and designing skills. Assume that this abstract application will be the start of
a large scale application and is intended to serve the basis for other tree-like implementations.

If pressed for time, feel free to use comments to explain what you would do in a real scenario.

Provide all code, schema and build instructions to be able to run application outside your environment.
