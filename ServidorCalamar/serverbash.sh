#!/usr/bin/env bash
############## CLUB ATLETICO PLATENSE CAMPEON 2025 ###################
########       Servidor Web en Bash      ########
# Servidor http creado en Bash para uso educativo, y para poder modificarlo
# El server va a estar aceptando peticiones en el puerto 8888 (http://ip-del-servidor:8888)
# Para probar https decargar caddy (apt install caddy) y configurar en el su archivo 
# /etc/caddy/Caddyfile
#
# Para poder navegar por https por afuera del servidor
#
# /etc/caddy/Caddyfile 
# ip-del-server:8443 {
#    reverse_proxy ip-del-server:8888
#    tls internal
#}
#
#Para navegar por localhost
#
# 0.0.0.0:8443 {
#   reverse_proxy 127.0.0.1:8888
#   tls {
#     issuer internal
#   }
# }
# Instalar socat (En sistemas basados en Debian "sudo apt install socat")
#
# Recuerden dar permisos de ejecucion al script (chmod +x serverbash.sh)
# Christian Iacobellis (iacobellis.christian@gmail.com)
# -----------------Al ser Educativo va con explicacion----------------------
#
# Configuracion Inicial

#trap "" PIPE # Esto evita que Bash muestre: Broken pipe

PUERTO=8888 # El puerto de escucha del Servidor
IP_SERVIDOR="0.0.0.0" # Escucha en todas las interfaces (LAN, localhost, etc). 
RAIZ="./" # Carpeta Raiz donde toma el index.html

# MULTIDOMINIO
declare -A DOMINIOS
DOMINIOS["localhost"]="./" # Dominio por defecto http://ip-o-localhost:8888
DOMINIOS["dominio1.com"]="./dominio1/" # Dominio 1 http://dominio1.com:8888
DOMINIOS["dominio2.com"]="./dominio2/" # Dominio 2 http://dominio2.com:8888
DOMINIOS["default"]="./" # Dominio por defecto (localhost http://ip-o-localhost:8888)

#Limites de conexiones y Seguridad
L_TIMEOUT=5 # Tiempo máximo en segundos para leer datos del cliente (anti slowloris) 
LIMITES_REQUEST=200 # Límite de tiempo entre requests por IP (en milisegundos)

#Manejo de Memoria del Server
declare -A CACHE # Cache en RAM de archivos (solo texto)

# Funcion de error
fatal(){ echo "[fatal] $*" >&2; exit 1; } # Muestra error y termina: >&2 → stderr, exit 1 -> corta ejecución
 
# Funcion mime, devuelve Content-Type según extensión
mime(){
  case "${1##*.}" in # Extrae extensión del archivo
    html|htm) echo text/html;; # HTML
    jpg|jpeg) echo image/jpeg;; # Todos los demas tipos de archivos
    png) echo image/png;;
    css) echo text/css;;
    js) echo text/javascript;;
    json) echo application/json;;
    txt) echo text/plain;;
    *) echo application/octet-stream;; # Default (binario)
  esac
}

#Logs

log(){
  (
    flock -x 200 # flock = herramienta para bloquear archivos
                 # -x = bloqueo exclusivo (solo un proceso puede escribir),200 = descriptor de archivo
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1 $2 $3" >> access.log # Genera la linea visual de datos para el access.log
    tail -n 200 access.log > access.tmp # toma las últimas 200 líneas y lo guarda en access.tmp
    mv access.tmp access.log # Reemplaza el log original con el recortado
  ) 200>access.lock # Abre (o crea) access.lock, lo asigna al descriptor 200, ese descriptor es el que usa flock
}

# Funcion ruta seguro

ruta_segura(){
  [[ "$1" == *".."* ]] && return 1 # Evita ataques tipo: ../../etc/passwd, Si encuentra .., devuelve error
  return 0
}

# Función para Respuesta HTTP 429 (rate limit)

enviar_error429(){ # Empieza la funcion
  BODY="<html>
  <head><title>429</title></head>
  <body style='font-family:sans-serif;text-align:center;margin-top:50px;background:#111;color:white;'>
  <h1 style='color:#ffd700;font-size:48px;'>429</h1>
  <p style='color:#ffd700;font-size:22px;'>Deja de spamear</p>
  <p style='color:#ffd700;font-size:22px;'>Refrescar para nuevas conexiones</p>
  </body>
  </html>"

  LONGITUD=${#BODY} # tamaño exacto del contenido, para que el navegador no falle 

  printf "HTTP/1.1 429 Too Many Requests\r\n"
  printf "Content-Type: text/html\r\n"
  printf "Content-Length: %d\r\n" "$LONGITUD"
  printf "Connection: close\r\n\r\n"
  printf "%s" "$BODY"
}

# Función para Respuesta HTTP 404

enviar_error404(){ # Empieza la funcion
  BODY="<html>
  <head><title>404</title></head>
  <body style='font-family:sans-serif;text-align:center;margin-top:50px;background:#111;color:white;'>
  <h1 style='color:#ff3b3b;font-size:48px;'>404</h1>
  <p style='color:#ff3b3b;font-size:22px;'>No encontrado</p>
  <p style='color:#ff3b3b;font-size:22px;'>El recurso no existe</p>
  </body>
  </html>"

  LONGITUD=${#BODY} # tamaño exacto del contenido, para que el navegador no falle 

  printf "HTTP/1.1 404 Not Found\r\n"
  printf "Content-Type: text/html\r\n"
  printf "Content-Length: %d\r\n" "$LONGITUD"
  printf "Connection: close\r\n\r\n"
  printf "%s" "$BODY"
}

# Seguridad de rutas completa

seguridad_ruta() {
  ruta_segura "$1" || return 1 # Usa la función anterior
  full_ruta="$RAIZ/$1" # Evita que se escape del directorio raíz
  [[ "$full_ruta" != "$RAIZ/"* ]] && return 1
  return 0
}

# Métodos HTTP

manejar_get() { # inicia la funcion GET
  local ruta="$1"
  ruta=${ruta#/}
  ruta=${ruta:-index.html} # Si está vacío -> sirve index.html

  seguridad_ruta "$ruta" || { # Llama a la funcion seguridad_ruta
    printf "HTTP/1.1 403 Forbidden\r\n\r\n"
    return
  }

  full_ruta="$RAIZ/$ruta"

  if [[ -f "$full_ruta" ]]; then # Verifica que el archivo exista
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: %s\r\n" "$(mime "$full_ruta")"
    printf "Content-Length: %s\r\n\r\n" "$(stat -c%s "$full_ruta")"
    cat "$full_ruta" 2>/dev/null # Lo devuelve
  else
    enviar_error404 # Si no recibe nada da 404
  fi
}

manejar_post() { # inicia la funcion POST
  local ruta="$1"
  ruta=${ruta#/}

  seguridad_ruta "$ruta" || return # Llama a la funcion seguridad_ruta

  echo "$body" > "$RAIZ/$ruta" # Crea archivo con el contenido recibido http://ip/nuevoarchivo

  printf "HTTP/1.1 201 Created\r\n\r\nOK" # Envia OK cuando lo crea
}

manejar_put() { # inicia la funcion PUT
  local ruta="$1"
  ruta=${ruta#/}

  seguridad_ruta "$ruta" || return # Llama a la funcion seguridad_ruta

  echo "$body" > "$RAIZ/$ruta"

  printf "HTTP/1.1 200 OK\r\n\r\nOK" # Envia OK cuando hace el POST
}

manejar_patch() { # inicia la funcion PATCH
  local ruta="$1"
  ruta=${ruta#/}

  seguridad_ruta "$ruta" || return # Llama a la funcion seguridad_ruta

  if [[ -f "$RAIZ/$ruta" ]]; then
    echo "$body" >> "$RAIZ/$ruta" # Agrega contenido
    printf "HTTP/1.1 200 OK\r\n\r\nOK" # Envia OK cundo agrega contenido
  else
    enviar_error404 # Si no recibe nada da 404
  fi
}

manejar_delete() { # inicia la funcion DELETE
  local ruta="$1"
  ruta=${ruta#/}

  seguridad_ruta "$ruta" || return # Llama a la funcion seguridad_ruta

  if [[ -f "$RAIZ/$ruta" ]]; then
    rm -f "$RAIZ/$ruta"
    printf "HTTP/1.1 200 OK\r\n\r\nOK" # Envia OK cuando elimina
  else
    enviar_error404 # Si no recibe nada da 404
  fi
}

# Función principal de manejo de requests

Gestion(){
  local ip="${SOCAT_PEERADDR:-0.0.0.0}" # IP real cliente

  IFS=$'\r' read -r -t "$L_TIMEOUT" request || return # Lee la primera línea del request HTTP (GET /index.html HTTP/1.1)
  request=${request%$'\n'}

  read method ruta version <<< "$request" # Divide en: (method -> GET)(ruta -> /index.html)(version -> HTTP/1.1)
  
  local ahora=$(date +%s%3N) # El ahora (Tiempo actual) es en milisegundos ## agregado

  # RATE LIMIT con archivo compartido + flock
  # Detectar extensión antes de limitar

  ruta=${ruta%%\?*} # Elimina parámetros ?a=1
  ruta=${ruta#/} # Quita / inicial ## agregado
  ext="${ruta##*.}" # Extrae extensión ## agregado
  # NO limitar archivos estáticos
  ext="${ruta##*.}"
  if [[ ! "$ext" =~ ^(jpg|jpeg|png|css|js|ico)$ ]]; then # No limita archivos estáticos
    archivo="./tmp/bashserver_$ip" # Archivo donde se guarda los datos
    ahora=$(date +%s%3N) # Tiempo

    (
      flock -n 200 || exit 1 # Bloqueo para evitar concurrencia

      if [[ -f "$archivo" ]]; then
        # Calcula tiempo entre requests
        ultima=$(cut -d '|' -f2 "$archivo")
        diff=$((ahora - ultima))
        # Si es muy rápido -> bloquea (Error 429)
        if (( diff < LIMITES_REQUEST )); then
            enviar_error429
            exit 0
        fi

      fi

      echo "Esta IP esta ahora $(date '+%Y-%m-%d %H:%M:%S') hace (Milisegundos)|$ahora" > "$archivo" # Guarda timestamp actual

      ) 200>"$archivo.lock" || return # Abre (o crea) access.lock, lo asigna al descriptor 200, ese descriptor es el que usa flock
  fi

# Inicia el bloque de Multidomino
  host="default" # Variable host -> dominio (por defecto)
  content_length=0 # Tamaño delo body (para POST/PUT)

  while read -r -t "$L_TIMEOUT" line; do # Lee línea por línea del request HTTP, Ejemplo:
                                         # GET / HTTP/1.1
                                         # Host: dominio1.com
                                         # User-Agent: curl
    line="${line%%$'\r'}" # Limpia \r (porque HTTP usa \r\n)
    [[ -z "$line" ]] && break # Cuando encuentra línea vacía → termina headers

    case "$line" in # Analiza cada header
      Host:*) # Extrae el dominio
        host="${line#Host: }"
        host="${host%%:*}"
      ;;
      Content-Length:*)
        content_length="${line#Content-Length: }" # Guarda el tamaño del body (POST, PUT, etc.)
      ;;
    esac
  done

  # BODY
  body=""                                                            # Si hay contenido: 
  (( content_length > 0 )) && IFS= read -r -n "$content_length" body # Lee byte y lo guarda en el body

  log "$ip" "$method" "$ruta"
  # Normalizar host
  host=$(echo "$host" | tr '[:upper:]' '[:lower:]') # Convierte a minúsculas: DOMINIO1.COM -> dominio1.com
  host=${host//[^a-z0-9\.\-]/} # Limpia caracteres raros: evita ataques, solo permite letras y numeros

  # MULTIDOMINIO
  RAIZ="${DOMINIOS[$host]}" # Busca el dominio en el array: dominio1.com -> :/dominio!
  [[ -z "$RAIZ" ]] && RAIZ="${DOMINIOS["default"]}" # Si no existe → usa default (./)

# DEBUG
  echo "DEBUG host=$host raiz=$RAIZ ruta=$ruta" >&2 # Muestra internamente: dominio, carpeta usada, ruta pedida

  log "$ip" "$method" "$host $ruta" #  Guarda registro en access.log: FECHA HORA IP GET dominio1.com index.html

  case "$method" in #  Decide qué hacer según método
    GET) manejar_get "$ruta" ;; #  Sirve archivos (index.html, css, etc)
    *) printf "HTTP/1.1 405 Method Not Allowed\r\n\r\n" ;; # Métodos no soportados -> error 405
  esac

  case "$method" in # evaluación del valor de la variable $method
    GET) manejar_get "$ruta" ;; # llama a la función manejar_get (devolver archivos (HTML, CSS, etc))
    POST) manejar_post "$ruta" ;; # llama a la funcion manejar_post (guarda datos en un archivo)
    PUT) manejar_put "$ruta" ;; # llama a la funcion manejar_put (sobrescribe archivo completo)
    PATCH) manejar_patch "$ruta" ;; # llama a la funcion manejar_patch (agrega contenido al archivo (>>))
    DELETE) manejar_delete "$ruta" ;; # llama a la funcion manejar_delete (Borra el archivo)
    *) printf "HTTP/1.1 405 Method Not Allowed\r\n\r\n" ;; # Si el método NO es ninguno de los anteriores: responde 405
  esac

}

if [[ "$1" == "handler" ]]; then # Verifica si el script ($1) es ejecutado en modo handler
  Gestion # Si se cumple, ejecuta la función principal que procesa requests HTTP
  exit 0 # 0 = ejecución exitosa
fi

# Funcion principal (parametros para ejecutar el servidor web)
funcion_principal(){
  # Limpiar archivos temporales al iniciar
  rm -f ./tmp/bashserver_* ./tmp/bashserver_*.lock 2>/dev/null
  set +m
  # Límites del sistema
  ulimit -n 10000 # Máx archivos abiertos
  ulimit -u 2000 # Máx procesos

  echo "Servidor en http://$IP_SERVIDOR:$PUERTO" # Muestra datos de la conexion - Mensaje...
  echo "RAIZ: $RAIZ" # Muestra carpeta donde consume el index.html

# Función matar_proceso
matar_proceso() { # Se va a ejecutar cuando ocurra un evento (Ctrl+C, Ctrl+Z, etc.)
  printf "\rCerrando servidor ServerCalamar...\n" # Sirve para pisar el ^Z visualmente
  kill $PID 2>/dev/null # Mata el proceso principal 
  exit                  # $PID: es el ID del proceso que guardaste con $!,kill: envía señal SIGTERM (cierre normal)   
}                       # 2>/dev/null: oculta errores si ya estaba muerto,exit: Termina completamente el script

trap matar_proceso INT TERM TSTP # Captura la señal y la mata

# Levantar en background 
  # socat -4 -d -d -T 5 \ Abre un subshell (un proceso hijo)
  # Lanza el servidor socat: -4 -> fuerza IPv4, -d -d -> debug (logs), -T 5 -> timeout
  # TCP-LISTEN:$PUERTO,reuseaddr,fork,max-children=50 \ Configuración del socket: TCP-LISTEN -> escucha conexiones
  # reuseaddr -> permite reusar puerto
  # fork -> cada conexión crea proceso, max-children=50 -> límite conexiones simultáneas
  # SYSTEM:"$0 handler" 2>&1 \ Ejecuta tu script en modo handler: $0 -> nombre del script actual, 
  # handler -> parámetro que usás arriba 
  # 2>&1 -> junta stderr + stdout
  # | grep --line-buffered "accepting connection" \
  # | sed -u -E 's/^([0-9\/: ]+).*from AF=2 ([0-9\.]+):.*/[\1] Nueva conexion desde \2/'
  # grep filtra solo: conexion aceptada....
  # sed ransforma la línea:
  # de, fecha hora socat[...] conexion aceptada from AF=2 192.168.0.14:12345
  # a, [fecha hora] Nueva conexion desde 192.168.0.14 
  # ([0-9\/: ]+) → captura fecha/hora -> \1
  # ([0-9\.]+) → captura IP -> \2
(
  socat -4 -d -d -T 5 \
  TCP-LISTEN:$PUERTO,reuseaddr,fork,max-children=50 \
  SYSTEM:"$0 handler" 2>&1 \
  | grep --line-buffered "accepting connection" \
  | sed -u -E 's/^([0-9\/: ]+).*from AF=2 ([0-9\.]+):.*/[\1] Nueva conexion desde \2/'

) | while read -r line; do # lee cada línea del log una por una
  (                        # abre otro subshell
    flock -x 200           # -x bloqueo exclusivo, 200 descriptor de archivo

    echo "$line" >> access.log # agregar línea nueva
 
    tail -n 200 access.log > access.tmp # dejar solo las últimas 200 lineas
    mv access.tmp access.log # Reemplaza el log original con el recortado

  ) 200>access.lock # crea el archivo lock
    done > /dev/null 2>&1 & # cierra el loop y lo manda a background

wait # mantiene el script activo,espera que procesos hijos sigan vivos y evita que el script termine

}

funcion_principal # Inicia servidor
