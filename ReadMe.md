# ReadMe

## Goal for the Hotkey Manager app

- menubar app with hotkey to display an overlay
- overlay displays a hierarchical list next to a keyboard layout
- overlay is always on top of the screen
- UI is updated as items are received

- by default shows all hotkeys for the currently selected application

- allow for hotkey creation, changing, editing, and deleting
- allow for removing app hotkeys

- allow for hiding hotkeys from the overlay
- allow for highlighting hotkeys in the overlay

### Additional features

- detect keyboard layout changes
- global hotkeys view for macOS hotkeys and menubar app hotkeys
- display error for duplicate hotkeys
- highlight hotkeys for currently pressed keys
- importing adobe hotkey configurations
- allow for adding representative dummy hotkeys to the overlay
- hotkey list includes menu separators if between hotkeys

## Getting Started

For retrieving current hotkeys, entry point is ApplicationServices and AXUIElement
AXChildren allows for traversing the menu hierarchy

Below is a snippet of the menu hierarchy for a Xcode MenuBar element
```
<AXApplication: “Xcode”>
 <AXMenuBar>
  <AXMenuBarItem: “Edit”>
   <AXMenu>
    <AXMenuItem: “Format”>
     <AXMenu>
      <AXMenuItem: “Text”>
       <AXMenu>
        <AXMenuItem: “Writing Direction”>
         <AXMenu>
          <AXMenuItem: “   Default”>

Attributes:
   AXIdentifier:  “makeBaseWritingDirectionNatural:”
   AXEnabled:  “0”
   AXFrame:  “x=833 y=514 w=124 h=22”
   AXParent:  “<AXMenu>”
   AXSize:  “w=124 h=22”
   AXMenuItemCmdGlyph:  “(null)”
   AXRole:  “AXMenuItem”
   AXMenuItemPrimaryUIElement:  “(null)”
   AXMenuItemCmdModifiers:  “8”
   AXPosition:  “x=833 y=514”
   AXTitle:  “   Default”
   AXHelp:  “(null)”
   AXMenuItemCmdChar:  “(null)”
   AXRoleDescription:  “menu item”
   AXSelected (W):  “0”
   AXMenuItemCmdVirtualKey:  “(null)”
   AXMenuItemMarkChar:  “✓”
```

Hotkey is stored either as localized string using *AXMenuItemCmdChar*
or as keyCode using *AXMenuItemCmdVirtualKey*


Editing hotkeys is done through 
*~Library/Preferences/* .plist files for each app, 
so is editing native macOS hotkeys


## Current Questions

1. Model Structure
My current layout is as follows:
- Application
    - Children: **MenuItem?**
    
- MenuItem
    - Parent: **Application**
    - Parent: **MenuItem?**
    - Children: **MenuItem?**
    
This is only to the fact that I haven't been able 
to implement a model that represents a section while traversing the menu.

A better approach would be to have a model 
that represents a section and a model that represents a hotkey?
- Application
    - Children: **Section?**
    
- Section
    - Parent: **Application**
    - Parent: **Section?**
    - Children: **Section?**
    - Children: **MenuItem?**
    - Children: **Hotkey?**

- should "menuItem representing a section" be a separate model?
- should "hotkey menuItem" be a separate model?

2. How to handle mixed models in traversal while persisting item relationships
- this is mostly regarding MenuBarService and its *traverseMenu* method

3. How to handle CoreData?
- should I use MVVM?

- how to make sure relations are correctly persisted and retrieved?

- I guess I'll need to first fetch for existing entities 
  before appending the items for display 
  to make sure userSettings are not overwritten.

- Is AsyncStream for traversal still feasible?


## Development Resources

### MenuBar Traversal

ApplicationServices and AXUIElement
https://developer.apple.com/documentation/applicationservices/axuielement_h

Useful App to inspect UIElement Attributes:
https://github.com/fruitsamples/UIElementInspector

Requires Accessibility Permissions, 
as well as App Sandboxing disabled
