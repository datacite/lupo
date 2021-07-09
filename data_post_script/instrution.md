## Post XML files to a port

<br/>

### Step 1

Check the "xml_post_parser_config.json" file for the configurations of the codes

Change if necessary

<br/>

### Step 2

From the config file, use the value of the field "xml_folder" as the name to create a folder in the same directory

Move the xml files to be posted to the folder

<br/>

### Step 3

Run the python script

```python
python xml_post_parser.py
```

### The XML files will now begin to be encoded into JSON files and then posted to the server port

<br/>

## Additional files

<br/>

`clear_folders.py`:

empty folders after posting (except "xml_src)

<br/>

`test_server.py`:

construct a dummy server using port 5000 in localhost

you can view the posted json files on http://localhost:5000/data

***Remember to change "server_port" in the config file to http://localhost:5000/ first***

