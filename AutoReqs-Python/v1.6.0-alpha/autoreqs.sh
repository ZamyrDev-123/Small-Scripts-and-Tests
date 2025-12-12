#!/bin/bash
# Bash >= 4.0
# v0.4.0-alpha 09/12/2025
# v0.8.0-alpha 10/12/2025 (stable)
# v0.9.0-alpha 11/12/2025
# v1.0.0-alpha 11/12/2025 (01:12 AM)
# v1.6.0-alpha 11/12/2025
# By ZamyrDev

# Version handling:
# X.Y.Z-STATUS, where:
# X : functional, important update.
# Y : new features, changes to existing features.
# Z : bugs fixed for release
# (The reboot of Y and Z is for when X updates)

# Windows cmd (limited concept):
# python3 -m pip freeze | findstr "library" > requeriments.txt
# type ./requeriments.txt

# Output error handling
# 1: syntax error, missing arguments, too many arguments
# 2: file/dir not found or does not exist, pip not working

# Add: --library/-lib to specific libraries/modules, and --out/-o for rename te output file, detect if there is a venv to load or if it is not necessary (automate, add option for the user). <- paraesta implementación, tengo anotado la definición en mi bloc de notas. (puedo comprobar al inicio la funcionalidad de pip en segundo plano)

# For debugging
set -e # exits inmediately if the exit state is not zero
#set -u # error if a variable does not exist
#set -x # print the command and its arguments to the stdout after expanding them, before executing them

args=3
typef=false

#OLDIFS=$IFS
# change it: IFS=$'\n' # line breacks only

# Error handling
function execute_if_something_fails() {
    echo -e '\nAn error has ocurred, please check...'
} # trap 'echo "Caught signal SIGHUB"' HUP # a signal is received
# configure the trap to call a function when an error occurs (ERR)
trap execute_if_something_fails ERR

# Parameters:
# 1: file/dir to extract reqs
# 2: specific lib/module pattern
# 3: (optional) output dir

if [ "$#" -eq 0 ] || [ "$#" -gt $args ]; then
    echo "Error: incorrect syntax!. Usage:"
    echo "$0 [File/Dir to extract Library/Module requeriments (main.py)] [Lib/module pattern] [Output directory (optional)]"
    exit 1
fi

# check that the objetive exist (in such case)
if ! [ -e "$1" ]; then
    echo "Error: file not found!. Try again."
    exit 2
fi

# check if that is a directory or a file
if [ -d "$1" ]; then
    echo "Directory detected."
    typef=dir
elif [ -f "$1" ]; then
    echo "File detected."
    # check if that is empty
    if ! [ -s "$1" ]; then
        echo "Error: the file is empty"
        exit 2
    else typef=file
    fi
fi

echo ''

# check where the output file will be saved (default working directory)
if ! [ -z "$3" ]; then
    c_outfile=true
else
    c_outfile=false
fi

# configure output file depending on whether argument #1 is a file or directory
if [ $c_outfile == true ]; then
    if [ -d "$3" ]; then
        outdir="$3"
    else
        outdir="$(dirname "$(realpath "$1")")"
    fi
elif [ $c_outfile == false ]; then
    if [ $typef = dir ]; then
        outdir="$1"
    else
        outdir="$(dirname "$(realpath "$1")")" # dirname of the file (PADER)
    fi
fi

# Check if Python PyPi works sucessful:
# (redirects the stdout [1] and stderr [2] to /dev/null)
pip3 --version > /dev/null 2>&1 || pip --version > /dev/null 2>&1 # or ... &>/dev/null
pip install requests &>/dev/null

if ! [ $? -eq 0 ]; then
    echo 'Error: pip is not installed, is not in the Path, or does not have Venv (Virtual Enviroment).
Any of these problems could be solved with one of these three options:

  - Download and install pip:
  $ curl -O https://bootstrap.pypa.io/get-pip.py
  $ python3 get-pip.py  OR  python3 -m ensurepip --upgrade
  (https://pip.pypa.io/en/stable/installation/)

  - Add to the Path (the file varies depending on the shell):'
    echo "  Edit your file $HOME/.bashrc (or .zshrc/.fishrc)"
    echo '  Add in the end: PATH="$PATH":/absolute/path/to/the/python/folder/

  - Create a virtual enviroment for pip:
  $ python3 -m venv custom_venv_folder
  # Temporarily load the venv
  $ source ./custom_venv_folder/bin/activate  OR  . ./custom_venv_folder/bin/activate
  # Deactivate the venv once you are no longer going to use it
  $ deactivate

  * And for the previous solution,
    it can be automated using the parameter:
    --venv [/venv/folder]
'
    # añadir porción que detecte tu tipo de shell y lo ajuste de forma automática (por sesión de terminal, ya que la mayori lleva bash integrado pero podrían estar usando otro, $SHELL) (y añadir colorcitos en futuras versiones estable, juaz juaz!!).
    exit 2
else
    echo '* Pip detected sucessfuly.'
    echo ''
    # aquí cargaria el resto de cosas en caso de automatización (lo de --venv debe cargar detectándolo como parámetro [usar case y es más avanzado])
fi


# ls:
# -1 : list files by line
# -A : show hidden files/folders (whitout . and ..)
# -F : adds / to the end of the folders in thelist
# -l : long list format (more data)
# -S : sorts files by size (largest at the top and smallest at the bottom)
# -R : recursive listing
# -N/--literal : entries exactly as they are (without quoation marks)
# -Q/--quoting-name : enclose the entry names in quoation marks

# 'read' command captures user input (standar input, stdin) and stores that text in one or more variables.
# with '-r' flag does no discriminate against spacial character (/, *, $var, etc).
# In combination with the '<<<' (here-string) operator, we can pass text as input
# (Exp.: <<< "text input" read save_variable) (-s for hide entry) (-a to save as an array)

# \0 : null line break

if [ $typef = dir ]; then
    echo "Checking files..."
    #echo ''
    # Listing items
    # The 'mapfile' command with the "-d ''" option uses the null character (\0) to separate each element within a string.
    # Each element ends with a null character, and the "-t" option removes these, leaving the elements separated.
    # The '< <(...)' command creates a subprocess for the commands within the '(...)' syntax and redirects its 'stout' to the 'stdin' input of the 'mapfile' command.
    mapfile -d '' -t pyfiles < <(find "$1" -name '*.py' -print0) # -maxdepth in the 'find' command to delimit the recursive function

    # respecto a $pyfiles, es una array (matríz), que si se hace un 'echo ${pyfiles[@]' ó 'echo $pyfiles' (es valido, porque si la variable contiene más de un elemento, se interpreta como una lista [ojo: solo con el bucle for, aunque parece que con echo también]) sin comillas dobles, se listara separando cada elemnto con el valor predeterminado de IFS (Internal Field Separator, que es: espacio, tabulador y salto de línea), pero si se coloca entre comillas dobles, se respeta el delimitador asignado ('' -> \0)

    # The -i option allows you to search for patterns regardless of whether they are uppercase or lowercase. (ignore case)
    # The -r option allows you to search through all files in a directory and its subdirectories. (recursive search)
    # The -v option finds lines that do not match the pattern. (invert match)
    touch "$outdir"/requirements.txt
    # creates a temporary file and print its path (X^n is the number of random characters, minimum X^3)
    temp_req=$(mktemp /tmp/requirements.autoreqs.XXXX || mktemp /var/tmp/requirements.autoreqs.XXXX)
    for file in "${pyfiles[@]}"; do
        # Nuevo mejorado (mío pero puede dar falsos positivos si encuentra algo con import/from)
        # con -o muestra solo el patrón (ó usar: ... | awk '{print $2}', que puede ser util para buscar libs)
        # grep -i "$2" "$file" | grep -e 'import' -e 'from' | awk '{print $2}' >> $temp_req
        # (versión robustísima de gemini xD)
        # * grep -i -E "^(import|from) .*\b$2\b" "$file" | awk '{print $2}' >> $temp_req
        # (versión super robustísima de gemini, admite evitar '.' y '_' para cosas como: xmodulo.xcosadelmodulo)
        grep -i -E "^(import|from)\s+\b$2(\s|\.|$)" "$file" | \
        awk '{
            lib = $2;
            # Si "lib" (campo $2) contiene un punto, sustituye el punto
            # y todo lo que le sigue con una cadena vacía.
            sub(/\..*/, "", lib)
            # sub(/patrón_quitar/, por_esto, en_esto)
            # sustituye (sub) "\..*" (punto literal "\." seguido de cualquier cosa ".*")
            # por una cadena vacía ("") dentro de la variable "lib"
            print lib
        }' >> $temp_req # '\' representa que sigue en la siguiente línea
        # lo que hace es cambiar el '.*' (que dejaba cualquier cosa) por un '\s' (un carácter de espacio/tabulador), forzando a que haya al menos un espacio, '+' más lo que coincide '\b$2',
        # y que luego admite tres posibilidades que coincidan con un espacio/tabulación '\s', un punto literal '\.' (permite la coincidencia luego del punto) ó con el final de la línea '$' (inicio:'^', final:'$'). Y añade complejidad en awk para sustituir lo que es '.xcosa' en 'xmodulo.xcosa' por nada (borrarlo, dejando límpio el nombre)

        # (añade la opción '-o' a grep ó cambia '... .*\b$2\b" ...' ['\b' marca el inicio o final de una palabra, delimita la palabra 'por _' ya que '\b inicio' coincide y '\b final' no] para que solo muestre la palabra especifica en $2 [sino ocurren cosas como que si hay un xmodulo y un xmodulo_a y solo pediste el primero también te mostrará el segundo]) <- en resumen: con -o sera demasiado específica la busqueda, y con \b+awk le dices que no continue cuando vea un '_' (como xmod:incluido/xmod_a:no_incluido), colocando así solo el nombre "completo".
        # en este caso se una un solo grep con extensiones regulares extendidas (-E) para filtrar ambos criterios a la vez.
        # -i : ignore-case, -E : extended RegEx (regular expresions) permite cosas más complejas como los operadores.
        # ('^' : comienzo de línea, '|' : operador OR simple, '()' : contenedor para el OR simple, '.*' : ['.' coincide con cualquier caracter individual] ['*' coincide con cero o más ocurrencias del elemento que lo precede 'el punto'] coinciden con cualquier cosa [carácter/es] cualquier número de veces [incluida ninguna vez ni cosa])
        # Anterior: grep -o -i "$2" "$file" >> $temp_req # > overwrite, >> addition
        # or: $temp_req << <(grep -i "$2" "$file")
    done

    # Sorts the temporary file and removes duplicate lines
    # (-o/--output : specify the file where the output should be saved)
    # (-u/--unique : remove duplicate lines)
    sort -u "$temp_req" -o "$temp_req"

    # Creates an array from a file (each line is an element) (readarrya -> Bash v4.0+)
    # The -t option removes the trailing delimiter (line break, \n).
    readarray -t simple_reqs < $temp_req

    for lib in "${simple_reqs[@]}"; do
        # create venv if it does not exist: (implement later)
        #python3 -m venv ~/.venv
        python3 -m pip freeze | grep -i "$lib" >> "$outdir"/requirements.txt
    done

    # Idea of the concept but not functional
    #pyfiles=$(find "$1" -name "*.py")
    #for file in "${pyfiles[@]}"; do # the scalar variablo is not a real array (becomes a single-element array)
    #    pylist=("${pylist[@]}" $(ls --quoting-style=shell $(echo "$file")))
    #    echo "$file"
    #done

    # Alternativa (pero solo funciona para archivos en esa carpeta, sin recursividad):
    # establece la varibale de separación de campos (IFS) en nada temporalmente
    # el bucle continua hasta que el comando 'read' acabe de leer la lista de entrada (<<<) generada por 'ls -R ...'
    # y luego guarda cada nombre en una lista
    #  while IFS= read -r -d '' file; do
    #      pyfiles=("${pyfiles[@]}" $file)
    #  done <<< $(ls -R "$1"/*.py --quoting-style=shell) # ó $(find "$1" -maxdepth 1 -name '*.py')
    # es lo mismo que: (excepto que dentro de un $(comandos) se ignora el byte nulo '\0')
    # find "$1" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' archivo; do echo "$archivo"; done

elif [ $typef = file ]; then
    echo "Checking file..."
    touch "$outdir"/requirements.txt
    temp_req=$(mktemp /tmp/requirements.autoreqs.XXXX || mktemp /var/tmp/requirements.autoreqs.XXXX)
    # In this case, only the libraries/modules it contains are searched for
    grep -i -E "^(import|from)\s+\b$2(\s|\.|$)" "$file" | \
    awk '{
        lib = $2;
        # Si "lib" (campo $2) contiene un punto, sustituye el punto
        # y todo lo que le sigue con una cadena vacía.
        sub(/\..*/, "", lib)
        # sub(/patrón_quitar/, por_esto, en_esto)
        # sustituye (sub) "\..*" (punto literal "\." seguido de cualquier cosa ".*")
        # por una cadena vacía ("") dentro de la variable "lib"
        print lib
    }' >> $temp_req

    # Sorts the temporary file and removes duplicate lines
    # (-o/--output : specify the file where the output should be saved)
    # (-u/--unique : remove duplicate lines)
    sort -u "$temp_req" -o "$temp_req"

    # security measure in case more than one lib/modl is obtained
    readarray -t simple_reqs < $temp_req

    for lib in "${simple_reqs[@]}"; do
        python3 -m pip freeze | grep -i "$lib" >> "$outdir"/requirements.txt
    done

fi

# So far it only works to recognize the specific libraries/modules of the files in a specific directory (the most complex one).
# (añadir saltos de linea para que visualmente no atormente)

# Hay un detalle: busca el nombre especifico del modulo/lib, deberia de ser automático (buscando cualquier libreria luego de cualquier linea con import, tengo que ver eso)
# Luego: crear una versión simplificada que extraiga de forma automatica las libs/modulos de la carpeta actual donde se ejecute de todos los files.py o de uno solo o más archivos .py (o añadirlo a este como función automática u opcional)
# Este PROYECTO, pasará a la versión 1.x.x cuando se logren los dos objetivos (cargar libs/modules por un archivo[1] y por un dir[2])
# (por esto habrán versiones llamadas autoreqs-simple, autoreqs-complete, autoreqs-etc)

# end
#IFS=$OLDIFS
unset OLDIFS # once restored, it no longer depends on this
unset args
unset typef
unset pyfiles
unset pylist
unset simple_reqs
#if [ $c_outfile == true ]; then
#    unset outdir
#fi
unset outdir
unset c_outfile
# comment to debugging
rm -f $temp_req # -f : force delete

if ! [ $? -eq 0 ]; then
    echo -e '\nAn error has ocurred, please check...'
else
    echo -e '\nDone'
fi

###### OJOJOJOJOJOJOJOJOOJOJO ####### Para añadir la atomatización de la busqueda de librerías podría crear un diccionario con 'pip freeze' local y luego buscar si alguno de los instalados se puede especificar la version (solo funcionaria si lo tienes instalado [para las versiones] o con un diccionario más grande [conseguir] funcionaría [pero sin version específica, a menos que lo detecte ._.]).
