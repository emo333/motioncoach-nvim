<!-- markdownlint-disable -->

# Suggestion Models: {documentation/mapping of suggestions} TODO: lots of work to be done here

================================================================================

---

---

## Beginner

### **`h`,`l` CURSOR MOVEMENTS**

Detection:

- more than 5 consecutive same key pressed.

Suggestion:

- "Use **`w`**/**`b`**/**`e`** to move cursor to next word / beginning of word / end of word."

---

### **`j`,`k` CURSOR MOVEMENTS**

Detection:

- more than 5 consecutive same key pressed.

Suggestion:

- "Use {count}**`j`** to move cursor down {count} lines. Example: **`6j`** moves cursor down 6 lines."
- "Use {count}**`k`** to move cursor down {count} lines. Example: **`23k`** moves cursor up 23 lines."

---

---

## Advanced

### COUNT COMPRESSION SUGGESTION

Detection:

-

Suggestion:

- ***

### TEXT OBJECT SUGGESTION

Detection:

-

Suggestion:

- ***

### VIMREGISTER SUGGESTION

Detection:

-

Suggestion:

- ***

### JUMPLIST SUGGESTION

Detection:

- line travel distance > 40( Configurable )

Suggestion:

- --JUMPLIST SUGGESTION--
  `<C-o>` backward | `<C-i>` forward | `` toggle'

  ***
