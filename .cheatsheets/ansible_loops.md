Ansible - Loops
===============

Ansible offers the loop, with_<lookup>, and until keywords to execute a task multiple times.

### Iterating over a simple list

```YAML
- name: Add several users
  ansible.builtin.user:
    name: "{{ item }}"
    state: present
    groups: "wheel"
  loop:
     - testuser1
     - testuser2
```

### Iterating over a dictionary

```YAML
- name: Register loop output as a variable
  ansible.builtin.shell: "echo {{ item }}"
  loop:
    - "one"
    - "two"
  register: echo
```

