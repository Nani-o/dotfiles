#!/bin/bash

PAGE=$(curl -k 'https://forum.waven-game.com/en/44-patchnotes-fr' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'Accept-Language: fr,fr-FR;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Cookie: LANG=en; PRIV={"v1":{"fbtr":{"c":"y","ttl":19777},"ggan":{"c":"y","ttl":19777},"otad":{"c":"y","ttl":19777},"fbok":{"c":"y","ttl":19777},"ggpl":{"c":"y","ttl":19777},"twtr":{"c":"y","ttl":19777},"dsrd":{"c":"y","ttl":19777},"pwro":{"c":"y","ttl":19777},"ytbe":{"c":"y","ttl":19777},"twch":{"c":"y","ttl":19777},"gphy":{"c":"y","ttl":19777},"ggmp":{"c":"y","ttl":19777}}}; _ga=GA1.1.1579437784.1693215671; _gcl_au=1.1.1743622750.1693215671; _ga=GA1.1.1579437784.1693215671; ssm_au_c=kO0iPAI+8ye5pz75W16rLnTIoKJsWktmQA02p/u8yObwgAAAAVt+1M1U23sBO3OW/Ica0JAqVtB9F5d/xlmnKb6Ibrc4=; cf_clearance=LGPfFa7kH2YSxCwRE_1cZ6l3CfuL12D6mHP3gxAUSvs-1693308499-0-1-412e2f73.43f3e899.162f7093-160.0.0; __cf_bm=JZrj0X_gkdMJ2IFwaljcdshNO1RC0.9TWso1hkmoqc0-1693308504-0-AXRiYv3COik6Cv7VG91/2bOil8R07UYhxkVOPcj4vk+VMTnEvEApLePDWVY0M28uMokrljZ4t/7tZ0zRP7z8ZF/KjHcJouVSAhPNLHgVVywR; SID=597e1aff5ec147be8f743a3c84d7eb81; announce=Nw%3D%3D; _gid=GA1.1.1166514716.1693308506; _ga_Q8GEXWM20Q=GS1.1.1693308505.2.1.1693308596.49.0.0' \
  -H 'Pragma: no-cache' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-Site: none' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.106' \
  -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  --compressed)

while read -r line
do
  TITLE=$(echo "$line" | cut -d ">" -f 2 | cut -d "<" -f 1)
  if grep -F "$TITLE" ~/.local/share/waven/patchnotes.txt > /dev/null
  then
    echo "Already seen"
  else
    echo "New patchnote"
    echo "$TITLE"
    mkdir -p ~/.local/share/waven
    echo "$TITLE" >> ~/.local/share/waven/patchnotes.txt
  fi
done <<< "$(echo "$PAGE" | grep ak-title-topic)"
