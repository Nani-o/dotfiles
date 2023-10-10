Bash - Operators
================

##### Integer comparison operators

```TABLE
| Operator | Meaning                                |
|----------|----------------------------------------|
| -eq      | Equal to                               |
| -eq      | Equal to                               |
| -ne      | Not equal to                           |
| -lt      | Less than                              |
| -le      | Less or equal to                       |
| -gt      | Greater than                           |
| -ge      | Greater or equal to                    |
| <=       | Less or equal to (used inside (()))    |
| >=       | Greater or equal to (used inside (())) |
```

##### Compound comparison operators

```TABLE
| Operator | Meaning                             |
|----------|-------------------------------------|
|-a        | Logical AND operator, similar to && |
|-o        | Logical OR operator, similar to ||  |
```

##### String comparison operators

```TABLE
| Operator | Meaning                                        |
|----------|------------------------------------------------|
| =        | Equals to (but for strings)                    |
| !=       | Not equal to (for strings)                     |
| <        | Less than (in ASCII alphabetical order)        |
| >        | Greater than (in ASCII alphabetical order)     |
| ==       | Double equals to (used to compare two strings) |
| -z       | The String is null                             |
| -n       | The String is not null                         |
```

##### File test operators

```TABLE
| Operator | Meaning                                                                                      |
|----------|----------------------------------------------------------------------------------------------|
| -e       | Check whether the file exists at a given path.                                               |
| -f       | Check whether the given file path points to a regular file or not.                           |
| -d       | Check whether the given path refers to an existing directory or not.                         |
| -h       | Finds whether the given path is a symbolic link.                                             |
| -L       | It checks for the symbolic link as the -h does and that link is not broken.                  |
| -b       | Checks for the block device.                                                                 |
| -c       | Checks for the character special file.                                                       |
| -p       | Checks for a named pipe (FIFO).                                                              |
| -s       | Used to find whether the file size is greater than zero or not.                              |
| -t       | Check whether the file descriptor is associated with the terminal or not.                    |
| -r       | Used to find whether the file is readable or not.                                            |
| -w       | Checks for whether the file is write permissions or not.                                     |
| -x       | It checks for the executable permissions for a specified file.                               |
| -g       | Checks for "set-group-ID" (SGID) permission set on a specific file.                          |
| -u       | Checks for "set-user-ID" (SUID) permission set on a specific file.                           |
| -k       | Look for the "sticky" bit is set or not on a specified directory.                            |
| -O       | Check whether the file exists and is owned by the current user.                              |
| -G       | Check whether the file exists and is owned by the same group as the user running the script. |
| -N       | Helps you check if the file has been modified since it was last read.                        |
| -nt      | Compares modification time of two files and determines which one is newer.                   |
| -ot      | This too compares the modification time of two files and determines which one is older.      |
| -ef      | Check whether two file paths refer to the same inode on the system.                          |
| !        | Reverses the result of a condition or command.                                               |
```
