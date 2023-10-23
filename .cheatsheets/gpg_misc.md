GPG - Misc
==========

##### Generate key

```SHELL
gpg --full-generate-key
```

##### Force pinentry

```SHELL
gpg --pinentry-mode loopback [...]
```

##### Export keys

```SHELL
gpg -a --export KEYID > public.asc
gpg -a --export-secret-key KEYID > secret.asc
```

##### Export all keys

```SHELL
gpg -a --export > public-all.asc
gpg -a --export-secret-key > secret-all.asc
```

##### Import keys

```SHELL
gpg --import keys.asc
```

##### Changing primary UID

```SHELL
gpg --edit-key KEYID
gpg>list
gpg>uid X
gpg>primary
gpg>save
gpg>quit
```

##### Edit key trust

```SHELL
gpg --edit-key KEYID
gpg>trust
gpg>(enter trust level)
gpg>save
gpg>quit
```