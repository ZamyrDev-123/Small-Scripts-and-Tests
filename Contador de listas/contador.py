### Contador (Prueba) ###
## Contador de personas ingresadas junto a sus datos.
## Script by ZamyrDev
## v1.0.2 tested - all correct. 

from os import system
system('clear')

count = 0
empty_list = []

while True:

    nombre = str(input("Nombre: "))
    edad = str(input("Edad: "))
    sexo = str(input("Sexo: "))

    system('clear')
    count += 1
    empty_list.append(nombre + ' ' + edad + ' ' + sexo)

    for data in empty_list:
        print(data)
        
    print(f"\n"+str(count)) # or len(empty_list)

    quit = str(input('Quit? '))

    if quit in ('s', 'y', 'S', 'Y', 'Si', 'Yes', 'si', 'yes'):
        exit()
    else:
        pass
exit()