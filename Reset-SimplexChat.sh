#!/usr/bin/env bash

DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUPS="$DIR/backups"

if [[ -t 1 ]]; then
  R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'
  C=$'\e[1;36m'; B=$'\e[1m'; D=$'\e[2m'; N=$'\e[0m'
else
  R=""; G=""; Y=""; C=""; B=""; D=""; N=""
fi

trap 'echo; echo -e "  ${Y}Cancelado.${N}"; exit 130' INT

pause() { echo; read -rp "  Pressione ENTER para continuar..." _; }

banner() {
  clear
  echo
  echo -e "  ${C}███████╗██╗███╗   ███╗██████╗ ██╗     ███████╗██╗  ██╗${N}"
  echo -e "  ${C}██╔════╝██║████╗ ████║╚════██╗██║     ██╔════╝╚██╗██╔╝${N}"
  echo -e "  ${C}███████╗██║██╔████╔██║ █████╔╝██║     █████╗   ╚███╔╝ ${N}"
  echo -e "  ${C}╚════██║██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝   ██╔██╗ ${N}"
  echo -e "  ${C}███████║██║██║ ╚═╝ ██║███████╗███████╗███████╗██╔╝ ██╗${N}"
  echo -e "  ${C}╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝${N}"
  echo -e "        ${Y}${B}R E S E T${N} ${D}••${N} ${Y}${B}P A D R Ã O   D E   F Á B R I C A${N}"
  echo -e "  ${D}──────────────────────────────────────────────────────────────${N}"
  echo
}

tam() { du -sh "$1" 2>/dev/null | cut -f1; }

checar_app() {
  if pgrep -f "simplex-desktop.AppImage" >/dev/null 2>&1; then
    echo -e "\n  ${R}[!]${N} O SimpleX Chat parece estar ${B}em execução${N}."
    echo -e "      Feche-o antes de continuar."
    read -rp "  ENTER para verificar novamente ou 'q' para sair: " r
    [[ "$r" == q ]] && exit 0
    checar_app
  fi
}

adicionar_logs() {
  local f
  for f in "$DIR"/hs_err_pid*.log; do
    [[ -e "$f" ]] && PATHS+=("$f")
  done
}

coletar() {
  PATHS=()
  local c
  for c in $1; do
    case $c in
      1) [[ -d "$DIR/dados" ]] && PATHS+=("$DIR/dados") ;;
      2) [[ -d "$DIR/config" ]] && PATHS+=("$DIR/config") ;;
      3) [[ -d "$DIR/cache" ]] && PATHS+=("$DIR/cache") ;;
      4) adicionar_logs ;;
      5) [[ -d "$BACKUPS" ]] && PATHS+=("$BACKUPS") ;;
    esac
  done
}

mostrar_lista() {
  local p
  for p in "${PATHS[@]}"; do
    printf "   %s%-8s%s %s\n" "$Y" "$(tam "$p")" "$N" "${p#"$DIR"/}"
  done
}

fazer_backup() {
  mkdir -p "$BACKUPS"
  local arq="$BACKUPS/simplex-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  local p
  local rels=()
  for p in "${PATHS[@]}"; do
    [[ "$p" == "$BACKUPS" || "$p" == "$BACKUPS"/* ]] && continue
    rels+=("${p#"$DIR"/}")
  done
  [[ ${#rels[@]} -eq 0 ]] && return 1
  echo -ne "\n  ${D}Criando backup...${N}"
  if tar -czf "$arq" -C "$DIR" "${rels[@]}" 2>/dev/null; then
    echo -e " ${G}ok${N} ${D}($(tam "$arq"))${N}"
    return 0
  fi
  echo -e " ${R}falhou!${N}"
  return 1
}

apagar() {
  local p
  for p in "${PATHS[@]}"; do rm -rf -- "$p"; done
}

pos_reset() {
  local r
  echo
  read -rp "  Iniciar o SimpleX agora? [s/N] " r
  [[ "$r" =~ ^[Ss]$ ]] && exec "$DIR/SimplexChat-inicializador.sh"
}

executar_reset() {
  local modo="$1"
  checar_app
  coletar "1 2 3 4"
  if [[ ${#PATHS[@]} -eq 0 ]]; then
    echo -e "  ${G}Tudo já está limpo — nada a apagar.${N}"
    pause; return
  fi
  banner
  echo -e "  ${B}RESET COMPLETO — o que será removido:${N}\n"
  mostrar_lista
  echo -e "\n  ${R}ATENÇÃO:${N} conversas, contatos e configurações serão ${B}perdidos permanentemente${N}."
  echo -ne "\n  Digite ${R}${B}SIM${N} para confirmar: "
  local r fez_backup=0
  read -r r
  if [[ "$r" != "SIM" ]]; then
    echo -e "  ${Y}Cancelado.${N}"
    pause; return
  fi
  if [[ "$modo" == "--backup" ]]; then
    fazer_backup && fez_backup=1
  else
    read -rp "  Criar backup antes de apagar? [S/n] " r
    [[ ! "$r" =~ ^[Nn]$ ]] && fazer_backup && fez_backup=1
  fi
  apagar
  echo -e "\n  ${G}✔ Reset concluído.${N} O SimpleX iniciará como novo."
  [[ $fez_backup -eq 1 ]] && echo -e "  ${D}Backup salvo em: $BACKUPS${N}"
  pos_reset
}

reset_seletivo() {
  local nomes=("Dados do chat (conversas e contatos)" "Configurações" "Cache" "Logs de crash" "Backups locais")
  local marcados=(0 0 0 0 0)
  local i r sel m
  while true; do
    banner
    echo -e "  ${B}RESET SELETIVO${N} ${D}— digite o número para marcar/desmarcar${N}\n"
    for i in 0 1 2 3 4; do
      if [[ ${marcados[$i]} -eq 1 ]]; then m="${G}[x]${N}"; else m="${D}[ ]${N}"; fi
      printf "   %b %s %s\n" "$m" "$((i+1))" "${nomes[$i]}"
    done
    echo
    echo -e "   ${G}a${N}) Marcar tudo   ${G}c${N}) Continuar   ${R}v${N}) Voltar"
    echo
    read -rp "  Opção: " r
    case $r in
      1|2|3|4|5)
        i=$((r-1))
        if [[ ${marcados[$i]} -eq 1 ]]; then marcados[$i]=0; else marcados[$i]=1; fi
        ;;
      a|A) marcados=(1 1 1 1 1) ;;
      c|C) break ;;
      v|V|q|Q) return ;;
    esac
  done
  sel=""
  for i in 0 1 2 3 4; do
    [[ ${marcados[$i]} -eq 1 ]] && sel+="$((i+1)) "
  done
  if [[ -z "${sel// }" ]]; then
    echo -e "  ${Y}Nada selecionado.${N}"
    pause; return
  fi
  checar_app
  coletar "$sel"
  if [[ ${#PATHS[@]} -eq 0 ]]; then
    echo -e "  ${G}Os itens selecionados já estão limpos.${N}"
    pause; return
  fi
  banner
  echo -e "  ${B}RESET SELETIVO — o que será removido:${N}\n"
  mostrar_lista
  echo -e "\n  ${R}ATENÇÃO:${N} esta ação não pode ser desfeita."
  echo -ne "\n  Digite ${R}${B}SIM${N} para confirmar: "
  read -r r
  if [[ "$r" != "SIM" ]]; then
    echo -e "  ${Y}Cancelado.${N}"
    pause; return
  fi
  read -rp "  Criar backup antes de apagar? [S/n] " r
  local fez_backup=0
  [[ ! "$r" =~ ^[Nn]$ ]] && fazer_backup && fez_backup=1
  apagar
  echo -e "\n  ${G}✔ Reset seletivo concluído.${N}"
  [[ $fez_backup -eq 1 ]] && echo -e "  ${D}Backup salvo em: $BACKUPS${N}"
  pos_reset
}

mostrar_status() {
  banner
  echo -e "  ${B}STATUS ATUAL${N}\n"
  local p t nlogs=0 f
  for p in dados config cache; do
    if [[ -d "$DIR/$p" ]]; then t="$(tam "$DIR/$p")"; else t="--"; fi
    printf "   %-8s %s%s%s\n" "$p" "$Y" "$t" "$N"
  done
  for f in "$DIR"/hs_err_pid*.log; do [[ -e "$f" ]] && nlogs=$((nlogs+1)); done
  printf "   %-8s %s%s arquivo(s)%s\n" "logs" "$Y" "$nlogs" "$N"
  local nb=0
  [[ -d "$BACKUPS" ]] && for f in "$BACKUPS"/*.tar.gz; do [[ -e "$f" ]] && nb=$((nb+1)); done
  printf "   %-8s %s%s backup(s)%s\n" "backups" "$Y" "$nb" "$N"
}

listar_backups() {
  banner
  echo -e "  ${B}BACKUPS SALVOS${N} ${D}($BACKUPS)${N}\n"
  if [[ ! -d "$BACKUPS" ]] || ! compgen -G "$BACKUPS/*.tar.gz" >/dev/null; then
    echo -e "  ${D}Nenhum backup encontrado.${N}"
    return
  fi
  ls -lht --time-style=long-iso "$BACKUPS"/*.tar.gz \
    | awk '{printf "   %s%-19s%s %-8s %s %s\n", "'"$Y"'", $6, "'"$N"'", $5, $7, $8}' \
    | sed 's|.*/||'
  echo
  echo -e "  ${D}Para restaurar: tar -xzf <arquivo> -C \"$DIR\"${N}"
}

while true; do
  banner
  echo -e "  ${B}MENU PRINCIPAL${N}\n"
  echo -e "   ${G}1${N}) Reset completo             ${D}(apaga tudo: dados + config + cache + logs)${N}"
  echo -e "   ${G}2${N}) Reset completo com backup  ${D}(salva um backup antes de apagar)${N}"
  echo -e "   ${G}3${N}) Reset seletivo             ${D}(escolha item por item o que apagar)${N}"
  echo -e "   ${G}4${N}) Status                     ${D}(uso atual dos diretórios)${N}"
  echo -e "   ${G}5${N}) Backups                    ${D}(listar backups salvos)${N}"
  echo -e "   ${R}0${N}) Sair"
  echo
  read -rp "  Escolha uma opção: " op || { clear; echo; exit 0; }
  case $op in
    1) executar_reset "" ;;
    2) executar_reset "--backup" ;;
    3) reset_seletivo ;;
    4) mostrar_status; pause ;;
    5) listar_backups; pause ;;
    0) clear; echo -e "\n  ${C}Até mais!${N}\n"; exit 0 ;;
  esac
done
