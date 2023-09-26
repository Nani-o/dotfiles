Ansible - Manipulating Data
===========================

## List

1. Combine lists

```YAML
vars:
  list1:
    - element1
    - element2

  list2:
    - element3
    - element4

  liste3: "{{ liste1 + liste2 }}"
```

This results in `['element1', 'element2', 'element3', 'element4']`

## Dictionnary

1. Combine dictionnaries

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
