
### Traductor de Decimal a Binario
## con Python3.x
## Por ZamyrDev in 19/02/2025 at 11:35am

a = 100 # Número en decimal

while a >= 1:
    b = a / 2
    c = a % 2
    a = b
    print("Dec:", a, "Bin:", c) # decimal - binario
    
# OJO: se debe de leer de abajo hacia arriba
#      y solo debe de tomarse el primer dígito
#      de la izquierda.