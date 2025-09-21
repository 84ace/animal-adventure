extends Node

const PORT := 7777
const TICK_RATE := 20.0

var _peer: ENetMultiplayerPeer
var _accum := 0.0

func _ready() -> void:
    _peer = ENetMultiplayerPeer.new()
    var err := _peer.create_server(PORT)
    if err != OK:
        push_error("Failed to bind ENet server on %d (err %d)" % [PORT, err])
        return

    var mp := MultiplayerAPI.new()
    mp.multiplayer_peer = _peer
    get_tree().set_multiplayer(mp)

    get_tree().get_multiplayer().peer_connected.connect(_on_peer_connected)
    get_tree().get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)
    print("Headless server listening on %d" % PORT)
    set_process(true)

func _process(delta: float) -> void:
    _accum += delta
    while _accum >= 1.0 / TICK_RATE:
        _tick()
        _accum -= 1.0 / TICK_RATE

func _tick() -> void:
    # TODO: world sim, replication, etc.
    pass

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
        if _peer:
            _peer.close()

func _on_peer_connected(id: int) -> void:
    print("Peer connected: ", id)

func _on_peer_disconnected(id: int) -> void:
    print("Peer disconnected: ", id)
