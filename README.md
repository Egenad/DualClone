# Proyecto DualClone

## Descripción general del proyecto
DualClone es un juego interactivo en el que dos jugadores pueden conectarse y competir entre sí utilizando tecnología Bluetooth y Peer-to-Peer (P2P). Los jugadores controlan naves espaciales que disparan balas y deben evitar los ataques del oponente. La aplicación está desarrollada en Swift para dispositivos iOS, aprovechando SpriteKit para la representación gráfica y CoreBluetooth junto con MultipeerConnectivity para la conectividad.

## Breve descripción de cada una de las funcionalidades o clases de la aplicación

### WelcomeController

Controlador principal que maneja la pantalla de bienvenida donde los jugadores pueden optar por crear o unirse a una sala de juego. Implementa los botones para iniciar como anfitrión (peripheral) o unirse como jugador (central). Una vez se establece la conexión, realiza el segue a la GameScene.

### GameViewController

Es el controlador que maneja la lógica del juego una vez que la partida ha comenzado. Configura la escena de juego y maneja la lógica de actualización de la partida.

### ConnectionManager

Es la clase que maneja la lógica de conexión Bluetooth y P2P. Contiene métodos para iniciar y unirse a una sala usando CoreBluetooth y MultipeerConnectivity. Así pues, gestiona el envío y recepción de datos entre los dispositivos conectados y maneja las notificaciones de conexión y desconexión.

### TransferService

Define los UUIDs para los servicios y características utilizados en la comunicación Bluetooth. También proporciona constantes para identificar diferentes tipos de mensajes intercambiados durante la partida para la comunicación Peer to Peer.

### GameScene

Clase que representa la escena del juego utilizando SpriteKit. Gestiona la aparición de la nave, las balas y el fondo animado (esto ocurre cuando una bala impacta sobre nuestra nave). Implementa la lógica de detección de colisiones y el manejo de daño. Utiliza el giroscopio del dispositivo para controlar la rotación de la nave (la cual afecta a su vez al ángulo de las balas disparadas).

## DEMO

(Esta demo se ha grabado utilizando la versión extendida de la práctica final):

[![DualClone DEMO](https://img.youtube.com/vi/iytsRvBKWtQ/0.jpg)](https://www.youtube.com/watch?v=iytsRvBKWtQ)
