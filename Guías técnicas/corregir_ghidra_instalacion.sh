#!/bin/bash
# Valido para Ghidra 11.4.2 (actual en octubre de 2025)
## Install build tools:
#* [JDK 21 64-bit][jdk]
#* [Gradle 8.5+][gradle] (or provided Gradle wrapper if Internet connection is available)
#* [Python3][python3] (version 3.9 to 3.13) with bundled pip
#* make, gcc/g++ or clang (Linux/macOS-only)

# NOTA: este archivo fue hecho en conjunto a la compilación de Ghidra 11.4.2 en mi máquina (Debian GNU/Linux 12 KDE Plasma 5.27.5).
# por eso está un poco desordenado (despúes lo ordeno jaja) y trato de solventar posibles fallos de diversas formas.
# Hechoen 3 días a de las 9:00 - 2:00 AM en promedio jajajaj (23/20/2025 tercrer día 10:00-11:30 PM).

# LEE DevGuide.md ó Readme.md en la carpeta de Ghidra para más información.
# Recomdación: en lo que se van corrigiendo errores ir probando con './gradlew '

# por si acaso
set -e

## 1: Deps del sistema ##

sudo apt install -y openjdk-21-jdk # o si lo tienes: temurin-21-jdk

# Instala Python
sudo apt install -y python3.11 # o lo más reciente disponible
# Pip y Venv
sudo apt install python3-venv python3-pip python3-pip-whl

# Crea el Virtual Env. (si llega a ser necesario, generalmente en Debian 12)
#python3 -m venv ghidra_py_env
# Inicialo
#source ghidra_py_env/bin/activate
python3.11 -m pip install setuptools wheel protobuf psutil
# ó
# Instalar todas las dependencias de Python necesarias
#pip install setuptools==68.0.0
#pip install wheel==0.37.1
#pip install protobuf==3.20.3
#pip install psutil==5.9.8
# Crear el directorio de dependencias si no existe


## 2: Deps manuales ##

# Opción 1: crear flat repo
mkdir -p flatRepo # ghidra solo necesita saber de su existencia
# Opción 2: crear ghidra.repos.config si no sirve la opción 1
touch ghidra.repos.config
echo "flatRepo = flatRepo" >> ghidra.repos.config

# compilador
sudo apt install make cmake build-essential git gcc

# OJO: debes descargar Gradle 8.5 o mayor y añadir a tu $HOME/.bashrc ó $HOME/.shrc:
# PATH=$PATH:/carpeta/del_binario_gradle/

# Forzar la adición de repositorios externos
# modifica build.gradle (debo agregar eso a la línea especifica o reemplazar texto con '| sed', por ahora esta es la forma manual)
nano build.gradle
#/*********************************************************************************
# * Prevent forked Java processes from stealing focus
# *********************************************************************************/
#allprojects {
#	tasks.withType(JavaForkOptions) {
#		jvmArgs '-Djava.awt.headless=true'
#	}
#
#	// *** CÓDIGO AÑADIDO/MODIFICADO AQUÍ ***
#	repositories {
#        // Habilitar repositorios públicos para que 'setupDev' pueda descargar dependencias
#        mavenCentral()
#        jcenter()
#    }
#	// *** FIN CÓDIGO AÑADIDO/MODIFICADO AQUÍ ***
#}
#
#/*********************************************************************************
# * Use flat directory-style repository if flatRepo directory is present.
# *********************************************************************************/
#def flatRepo = file("${DEPS_DIR}/flatRepo")
#if (flatRepo.isDirectory()) {
#	allprojects {
#		repositories {
#			mavenLocal()
#           //mavenCentral() // tambiéñ modificado (se comentó)
#			flatDir name: "flat", dirs:["$flatRepo"] // <<-- DEJA SOLO flatDir AQUÍ
#		}#
#	}
#}
#...

# ¿Por qué funciona esto? (explicación por Gemini) # 1
# El buildscript de Ghidra desactiva intencionalmente los repositorios públicos por defecto.
# La tarea setupDev está diseñada para activarlos temporalmente, descargar los archivos al flatRepo y luego deshabilitarlos.
# Dado que la tarea setupDev parece fallar antes de lograr su objetivo, la solución es bypassear ese mecanismo y añadir los repositorios manualmente.
#
# Al añadir mavenCentral() y jcenter(), le estás dando a Gradle la capacidad de encontrar y descargar todas esas dependencias listadas (como guava, dex-ir, asm, etc.), permitiendo que la configuración del proyecto finalice y que la compilación (la fase build) pueda comenzar.
#
# Nota: Una vez que la compilación sea exitosa, puedes considerar eliminar las líneas de mavenCentral(), jcenter(), etc., del build.gradle para restaurar la configuración original de seguridad del proyecto.
#
# Resumen del cambio: # 2
# Al poner mavenCentral() y jcenter() fuera de la condición if (flatRepo.isDirectory()), te aseguras de que el sistema siempre tenga acceso a Internet para descargar dependencias, lo cual es vital para que la tarea setupDev funcione y pueble tu directorio flatRepo.

# Descarga manualmente yajsw-13.12.zip para crear el ZIP de Ghidra (al compilar)
# Opción 1: descarga manual
cd Ghidra/Features/GhidraServer
wget https://github.com/glub/secureduck/raw/master/lib/yajsw-stable-13.12.zip
# ó desde SourceForge
wget https://sourceforge.net/projects/yajsw/files/yajsw/yajsw-stable-13.12/yajsw-stable-13.12.zip
# Opción 2: verifica la URL en el archivo de configuración
cat Ghidra/Features/GhidraServer/build.gradle | grep yajsw
# Opción 3: deshabilitar GhidraServer (si no lo necesitas)
nano settings.gradle # edita este archivo
# y comenta: include 'Ghidra/Features/GhidraServer'
# Quedaría así:
# // include 'Ghidra/Features/GhidraServer'
# Opción 4: has './gradlew clean' y luego './gradlew buildGhidra'

## 3: Compilación de Ghidra 11.4.2 ##

# Antes de ejecutar ./gradlew en la carpeta de ghidra 11.4.2
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
# si es temurin cambialo por "temurin-21-jdk-amd64"

# Por fin...
./gradlew clean # limpia cualquier build anterior
./gradlew setupDev # build ó support (depende de la versión)
./gradlew buildGhidra # compilar Ghidra


## 4: En caso de Error con AXMLPrinter2 (:FileFormats) ##

# Opción 1: re-ejecutar setupDev (eso cuando "./gradlew clean" da este error)
./gradlew setupDev

# Opción 2: Ubicar o Proporcionar AXMLPrinter2 Manualmente (explicación de Gemini)
# Si setupDev sigue fallando, la dependencia :AXMLPrinter2 podría estar definida como un subproyecto en el sistema de build de Ghidra y no pudo ser configurada.
# Para la versión 11.4.2 de Ghidra, el artefacto AXMLPrinter2 (y otros como sevenzipjbinding) debe ser descargado.
#
# Verifica si la dependencia es un subproyecto:
# 1. Revisa el archivo "settings.gradle" en la raíz de tu proyecto
# 2. Busca si hay un proyecto incluido llamado AXMLPrinter2.
# Si no está definido como un subproyecto o si el problema persiste, es una señal de que la configuración de la dependencia AXMLPrinter2 no está señalando correctamente el flatRepo.

# Pasos a seguir si setupDev falla de nuevo:
# A menudo, la solución más directa es ejecutar la tarea principal de build de Ghidra, que forzará la inicialización de los subproyectos:
./gradlew buildGhidra

# Si aún falla con el mismo error, significa que la configuración del proyecto aún no está lista. Revisa la documentación de Ghidra para la versión 11.4.2 y la construcción desde código, ya que este error apunta a una configuración inicial incompleta que es específica del proyecto Ghidra.
# En resumen, el siguiente paso lógico y obligatorio para Ghidra es que la tarea setupDev complete la descarga de dependencias al flatRepo. Si tu modificación en build.gradle es correcta, setupDev debería funcionar ahora.

# Opción 3: Descargar e instalar AXMLPrinter2 y otras deps para Android (si no sirvio la opción 2)
# El paquete AXMLPrinter2.jar se necesita para procesar archivos APK de Android. Lo descargaremos de un repositorio de GitHub que lo tiene disponible.

# A. Navegar a la carpeta flatRepo
#Asegúrate de estar en el directorio raíz de Ghidra y ve a la carpeta que debe contener todas las dependencias locales:
cd flatDir

# 1. Descarga el .jar de las deps
curl -OL https://github.com/digitalsleuth/AXMLPrinter2/raw/main/AXMLPrinter2.jar
# O si prefieres wget:
# wget https://github.com/digitalsleuth/AXMLPrinter2/raw/main/AXMLPrinter2.jar

# Descargar el paquete dex2jar (versión estable o la mencionada en el código fuente de Ghidra)
# Usaremos la versión más reciente que sea compatible

# 2. dex-ir
curl -OL https://repo1.maven.org/maven2/de/femtopedia/dex2jar/dex-ir/2.4.24/dex-ir-2.4.24.jar

# 3. dex-reader
curl -OL https://repo1.maven.org/maven2/de/femtopedia/dex2jar/dex-reader/2.4.24/dex-reader-2.4.24.jar

# 4. dex-reader-api
curl -OL https://repo1.maven.org/maven2/de/femtopedia/dex2jar/dex-reader-api/2.4.24/dex-reader-api-2.4.24.jar

# 5. dex-translator
curl -OL https://repo1.maven.org/maven2/de/femtopedia/dex2jar/dex-translator/2.4.24/dex-translator-2.4.24.jar

# 6. Descarga el archivo SARIF faltante. Usaremos un mirror confiable
curl -OL https://github.com/NationalSecurityAgency/ghidra-data/raw/master/dependencies/java-sarif-2.1-modified.jar
# ó
curl -OL https://repo1.maven.org/maven2/com/contrastsecurity/sarif/java-sarif-2.1-modified/2.1.0/java-sarif-2.1-modified-2.1.0.jar
# Renombra el archivo a la convención que Ghidra busca:
mv java-sarif-2.1-modified-2.1.0.jar java-sarif-2.1-modified.jar
# ó
wget https://github.com/NationalSecurityAgency/ghidra/files/10002871/java-sarif-2.1-modified.jar
# ó
wget https://github.com/c4-project/ghidra-data-dependencies/raw/master/java-sarif-2.1-modified.jar
# ó (funcional)
wget https://sources.voidlinux.org/ghidra-11.1.2/java-sarif-2.1-modified.jar
# ó ya no usar
#./gradlew buildGhidra --exclude-project :Sarif

# B. El flatDir de Gradle espera que los archivos sin grupo ni versión se llamen usando el patrón [nombre_artefacto]-[versión].[extensión], pero dado que este es un JAR especial sin versión definida en la dependencia, a menudo basta con un nombre simple o el nombre del artefacto.
# Probemos renombrar el archivo JAR para que coincida exactamente con lo que Gradle busca en un flatDir.

# Haz que el nombre del artefacto coincida con el nombre del JAR
# La forma más segura es ponerle una versión, por ejemplo, '1.0'
mv AXMLPrinter2.jar AXMLPrinter2-1.0.jar
cd ..

# C.a. Modifica build.gradle (Recomendado)
# Abre el archivo build.gradle en el directorio raíz de Ghidra.Busca la sección que define la variable flatRepo y modifica la línea tal como se indica a continuación:
# Antes (Original, incorrecto para tu setup)
#  def flatRepo = file("${DEPS_DIR}/flatRepo")
# Después (Correcto para tu setup)
#  def flatRepo = file("${projectDir}/flatRepo")
nano build.gradle

# Esta sección se encuentra justo después del bloque de código donde se define project.ext.DEPS_DIR = file("${projectDir}/dependencies") (aproximadamente 30 líneas después de tu bloque repositories).
# El bloque de código completo se verá así después de tu modificación:
# /*********************************************************************************
#  * Use flat directory-style repository if flatRepo directory is present.
#  *********************************************************************************/
# // [MODIFICACIÓN NECESARIA AQUÍ]
# def flatRepo = file("${projectDir}/flatRepo")
# if (flatRepo.isDirectory()) {
#	allprojects {
#		repositories {
#			mavenLocal()
#			//mavenCentral() // modified by zamyr
#			flatDir name: "flat", dirs:["$flatRepo"]
# 		}
#	}
# }
# //... el resto del archivo

# C.b. Mueve tu archivo a una carpeta llamada 'dependencies' (XD)
mkdir -p dependencies
mv flatRepo/ dependencies/

# renombra AXMLPrinter2-1.0.jar a AXMLPrinter2.jar si falla el paso C

# Asegurate de tener:
# export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
# si es temurin cambialo por "temurin-21-jdk-amd64"

# Preparar nuevamente y compilar
./gradlew clean --refresh-dependencies
./gradlew setupDev # omitir si da error con todas la dependencias satisfechas
./gradlew buildGhidra
# ó (si usaste un Python Env)
./gradlew buildGhidra -Pghidra.python3.path="$PWD"/ghidra_py_env/bin/python3
# ú omitir python
#./gradlew buildGhidra --exclude-project :PyGhidra --exclude-project :Debugger-rmi-trace

# si utilizaste un Venv de Python 3.11
# deactivate
# Si el error es que no puede descargar librerias de python:
mkdir -p dependencies/Debugger-rmi-trace
# Descargar setuptools manualmente
#cd dependencies/Debugger-rmi-trace
#wget https://files.pythonhosted.org/packages/68/1e/3ad4e2c3900f324b36e3142c573e5b0d997b6eb8eae16a89ff681f72e3e9/setuptools-68.0.0-py3-none-any.whl
# ó buscar en: https://pypi.org/project/setuptools/#files y https://pypi.org/project/wheel/#files
# ó descargar directo
# pip download --only-binary=:all: --platform linux_x86_64 --verbose <paquete> -dest /ruta/al/dir
#cd ../..

# Corregir error ":GhidraServer:ip"
# Opción 1: edita 'Ghidra/Features/GhidraServer/Module.manifest' y agrega
# MODULE FILE LICENSE: lib/yajsw-stable-13.12.zip Apache_2.0
# Opción 2: ubica correctamente el archivo 'yajsw-stable-12.12.zip' (sirve para la opción 1)
mv /home/zamir/Descargas/ghidra.bin/Ghidra/Features/GhidraServer/yajsw-stable-13.12.zip /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/Ghidra/Features/GhidraServer/lib/
# Opción 3: si yajsw no usa Apache 2.0, necesitas verificar su licencia real. yajsw generalmente usa:
# - Apache 2.0 (la más común)
# - LGPL
# - GPL
# Puedes verificar la licencia en el archivo descargado o en el sitio web oficial.
# Opción 4: deshabilitar GhidraServer (si no lo necesitas)
nano /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/settings.gradle
# comenta esta línea
# // include 'Ghidra/Features/GhidraServer'
# Al final: en el directorio GhidraServer, verifica qué archivos se esperan
find /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/Ghidra/Features/GhidraServer/lib/ -type f

# Opción 5: usa la que se encuentra en licenses/ usar en Module.manifiest:
# MODULE FILE LICENSE: lib/yajsw-stable-13.12.zip Apache_License_2.0
# Verifica que el archivo de licencia existe
ls -la /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/licenses/Apache_License_2.0.txt
# Verifica que el yajsw esté en lib/
ls -la /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/Ghidra/Features/GhidraServer/lib/yajsw-stable-13.12.zip
# Verifica el Module.manifest
cat /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/Ghidra/Features/GhidraServer/Module.manifest | grep yajsw
# Opción 6: ó descarga la licencia de Apache 2.0 (o la que requiera yajsw)
cd licenses/
wget https://www.apache.org/licenses/LICENSE-2.0.txt # licencia oficial
# Cambialo al nombre esperado por :GhidraServer:ip
mv LICENSE-2.0.txt Apache_2.0.txt
# el Ghidra/Features/GhidraServer/Module.manifiest debe contener:
# MODULE FILE LICENSE: lib/yajsw-stable-13.12.zip Apache_2.0

# Si sigue fallando el :GhidraServer:ip
# Diagnostica el error en: /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/build/reports/problems/problems-report.html
# Verifica el error a más detalle
./gradlew :GhidraServer:ip --stacktrace --info
# Dar permisos de lectura
chmod 644 Ghidra/Features/GhidraServer/lib/yajsw-stable-13.12.zip
# Verificar que el ZIP no esté corrupto
unzip -t Ghidra/Features/GhidraServer/lib/yajsw-stable-13.12.zip
# Limpiar cache específico del módulo
./gradlew :GhidraServer:clean
# Solucion rápida (ser consciente)
# Editar settings.gradle
nano /home/zamir/Descargas/ghidra-Ghidra_11.4.2_build/settings.gradle
# quedaría así: // include 'Ghidra/Features/GhidraServer'
# ó: ./gradlew buildGhidra -x :GhidraServer:assemble
./gradlew assembleDistribution # recompila

## OK: ERROR ESPECÍFICO CON 'yajsw' ##
# El archivo yajsw-stable-13.12.zip no tiene una entrada en el certification.manifest del módulo GhidraServer.
# Agrega una entrada al final del 'certification.manifiest'
nano Ghidra/Features/GhidraServer/certification.manifest
# agrega al final de la línea esto:
# lib/yajsw-stable-13.12.zip||Apache_License_2.0
# Verifica la entrada en certification.manifest
cat Ghidra/Features/GhidraServer/certification.manifest | grep yajsw


## EXTRA: optimizar compilación ##
# Máxima prioridad (-20), Mínima prioridad (+20)
ps faux | grep 'gradlew' | awk '{print $2}' # obten el PID del proceso (arg. #2)
# ó (más dinámico y extenso)
ps -axo pid,user,pri,ni,cmd | grep 'PID' && ps -axo pid,user,pri,ni,cmd | grep 'gradlew' # | awk '{print $1}' # opcional
# ó pgrep -a process_name
# Opción 1: si ya se está compilando (proceso en ejecución)
sudo renice -12 -p [PID process]
ps -o pid,user,pri,ni,pcpu,cmd -p [PID process] # coloca el PID de ./gradlew buildGhidra ...
# Opción 2: iniciar con prioridad 'niceless' [personalizada]
sudo nice -n -12 ./gradlew buildGhidra ... # por sudo da error, recomiendo opción 1

# PRI: (Prioridad dinámica) desde 0 (alta prioridad) hasta 39 (baja prioridad)
# NI: (Prioridad estática) desde -20 (alta prioridad) hasta +19 (baja prioridad)

# Y si ya tienes una parte lista puedes optar por:
# ./gradlew assembleDistribution

## Con esto en resumen sería ##
export JAVA_HOME="/usr/lib/jvm/temurin-21-jdk-amd64/" ; ./gradlew clean -Pghidra.python3.path="$PWD"/ghidra_py_env/bin/python3
export JAVA_HOME="/usr/lib/jvm/temurin-21-jdk-amd64/" ; ./gradlew buildGhidra -Pghidra.python3.path="$PWD"/ghidra_py_env/bin/python3 | tee .compile_out.txt


## 4: Finalmente, ejecutar Ghidra :D ##
cd build/Ghidra
# ó
cd build/dist/

# si se generó el ZIP de distribución tambien se puede encontrar en /build/dist
unzip ghidra_[version]_[fecha]_[linux_arch].zip

exit 0
