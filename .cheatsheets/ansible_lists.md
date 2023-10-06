Ansible - Lists
===============

##### Combine lists

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