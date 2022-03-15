# Contrato inteligente para compraventa de artículos - Daniel Carrasco Pérez
# 
# La forma más sencilla de realizar la compraventa de artículos a través de los contratos inteligentes es haciendo que tanto el vendedor como el comprador
# paguen el doble del precio del artículo en sí. Esto será totalmente un depósito para el vendedor y para el comprador será la mitad un depósito y la otra 
# mitad el pago por el artículo.
#
# Esto incentivará a ambas partes a estar interesados en terminar la transacción. De no ser así, el vendedor perderá el doble del precio del artículo y el 
# comprador pagará el doble por el mismo artículo. De esta forma, si ambos quieren recuperar su depósito, se interesarán en completar la transacción.
#
# A continuación, el código del contrato inteligente para este caso de compraventa de artículos. 

# @version ^0.2.16

# Variables del contrato
precio: public(uint256) # El precio del artículo que se vende con este contrato. Variable de tipo entero sin signo de 256
vendedor: public(address) # El creador de este contrato y vendedor del artículo. Variable de tipo de dirección de la cadena Ethereum
comprador: public(address) # El comprador del artículo. Variable de tipo de dirección de la cadena Ethereum
enviado: public(bool) #Estado del contrato: True significa que el artículo ha sido enviado, False significa que no se ha enviado aún. Variable de
                        # tipo booleano
bloqueado: public(bool) # Estado del contrato: True significa que hay un comprado y que ha pagado por el artículo, False significa que no hay comprador 
                        # aún. Variable de tipo booleano
completado: public(bool) # Estado del contrato: True significa que el comprador ha recibido el artículo, False significa que la transacción está aún en 
                         # un punto intermedio. Variable de tipo booleano

# Función constructora del contrato
@external
@payable
def __init__(): 
    assert (msg.value % 2) == 0, "Valor no divisible entre 2" # Comprobado que el precio sea divisible entre dos
    self.precio = msg.value / 2  # El vendedor inicializa el contrato poniendo un precio y pagando dos veces este precio
    self.vendedor = msg.sender # Guardamos la dirección del creador del contrato como "vendedor"
    self.bloqueado = False # Inicializamos la variable "bloqueado" a "False"

# Función para verificar y almacenar al comprador y bloquear el contrato para que no hayan más compradores
@external 
@payable 
def comprarArticulo(): 
    assert not self.bloqueado,"Este artículo ya se encuentra en proceso de compra." # Comprueba si hay comprador o no. Si no lo hay para a la siguiente línea
    assert msg.value == (2 * self.precio), "El precio pagado no corresponde con el precio del artículo." # Comprueba si el comprador está pagando el doble del precio del artículo o no. De ser así, pasará a la siguiente línea
    self.comprador = msg.sender # Guarda la dirección que ha hecho la llamada a esta función como "comprador"
    self.bloqueado = True # Cambia el estado del contrato a "bloqueado" para evitar que otros compradores puedan comprar el mismo artículo

# Función para actualizar el estado del contrato a enviado
@external
def articuloEnviado():
    assert self.bloqueado, "Este artículo no ha sido comprado aún." # Comprueba si el artículo ha sido comprado o no. Si lo ha sido pasa a la siguiente línea
    assert msg.sender == self.vendedor, "Cuenta no autorizada para esta acción." # Comprueba si la dirección que llama a esta función es el vendedor. Si lo es pasará a la siguiente línea
    self.enviado = True # Cambia el estado del contrato a "Enviado"

# Función para terminar el contrato, devolver los ETH a cada cuenta como corresponda y destruir el contrato una vez los ETH se han transferido
@external
def articuloRecibido(): # Función para comprobar que la compra se ha realizado y el comprador ha recibido el artículo, para así devolver los depósitos y destruir el contrato
    assert self.bloqueado, "Este artículo no ha sido comprado aún." # Comprueba si hay comprador o no. Si lo hay, quiere decir que se ha realizado el pago y pasará a la siguiente línea
    assert self.enviado, "Este artículo no ha sido enviado aún." # Comprueba si se ha enviado el artículo o no. Si se ha enviado pasará a la siguiente línea
    assert msg.sender == self.comprador, "Cuenta no autorizada para esta acción." # Comprueba si la dirección que llama a esta función es el comprador. Si lo es pasará a la siguiente línea
    assert not self.completado, "Este artículo ya no está disponible." # Comprueba si la transacción ha sido terminada o no. De no ser así, seguirá en la siguiente línea
    self.completado = True # Cambia el estado del contrato a "Completado"
    send(self.comprador, self.precio) # Devuelve al comprador el precio del artículo que puso como depósito
    selfdestruct(self.vendedor) # Devuelve al vendedor su depósito y le transfiere el precio del artículo que el comprador ha pagado. Después destruye el contrato

# Función para cancelar la venta del artículo
@external
def cancelarVenta(): # Función para abortar y destruir el contrato si no hay comprador aún
    assert not self.bloqueado, "Este artículo ya ha sido pagado. Por favor, complete la transacción." # Comprueba si hay comprador o no. Si no lo hay para a la siguiente línea
    assert msg.sender == self.vendedor, "Cuenta no autorizada para realizar esta acción." # Comprueba si la dirección que llama a esta función es el vendedor
    selfdestruct(self.vendedor) # Reembolsa al vendedor y destruye el contrato