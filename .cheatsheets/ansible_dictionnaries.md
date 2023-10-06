Ansible - Dictionnaries
=======================

##### Combine dictionnaries

```YAML
vars:
  dict1:
    key1: value1
    key2: value2

  dict2:
    key3: value3
    key4: value4

  dict3: "{{ dict1 | combine(dict2) }}"
```

This results in `{"key1": "value1", "key2": "value2", "key3": "value3", "key4": "value4"}`

If you want to merge not only top level keys, but also nested keys, you can use the `recursive` option:

```YAML
vars:
  dict1:
    key1: value1
    key2: value2
    key3:
      key3.1: value3.1
      key3.2: value3.2

  dict2:
    key3:
      key3.3: value3.3
      key3.4: value3.4
    key4: value4

  dict3: "{{ dict1 | combine(dict2, recursive=True) }}"
```

This results in `{"key1": "value1", "key2": "value2", "key3": {"key3.1": "value3.1", "key3.2": "value3.2", "key3.3": "value3.3", "key3.4": "value3.4"}, "key4": "value4"}`