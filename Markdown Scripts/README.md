# Markdown Scripts

## Description

Collection of PowerShell scripts to help with converting text/files to/from Markdown

### Convert-MarkDownToHtml

Takes a Markdown file input, converts the content to an html file, and applies a Cascading Style Sheet to make it more readable

### Convert-CommentsToMarkdown

Comments in the specified script file are parsed and those containing a version build style number are ordered and converted into a numbered markdown list that is copied to the clipboard or optionally written to a .md file in the same directory  

Comments need to start with 1.0.0, 1.1.0, 2.0.0, etc... and not contain gaps in the numbering sequence  
If there are gaps in the numbering sequence, the markdown file will be fine, but the list will be automatically renumbered when rendered/converted

#### License Info

All scripts released under an MIT license  
Links to GitHub project repos and license files are in the script headers
