//Start signal : $0000
//Steam flow: $0001
//RPV level: $0002
//Feedwater flow: $0003

Values:
    -reactor power
    -reactor water level
    -recirculation
    -rod position x12
    -rod temp x12
    -rod fuel values x12
    -rod selection
    -reactor pressure
    -reactor temperature
    -steam flow
    -feedwater flow
    -turbine rpm
    -generator load
    -turbine flow
    -bypass flow
    -phase difference
    -breaker sync

Controls:
    Feedwater valve (3 position switch, +/- feedwater flow)
    Recirc valve (3 position switch, +/- recirc)
    Rod movement lever (3 position lever, +/- selected rods position)
    Rod selection (12 individual buttons, sets rod selection)
    SCRAM (Button)
    Breaker sync (2 position lever)
    Turbine valve (3 position switch, +/- turbine valve)
    Bypass valve (3 position switch, +/- bypass valve)
Displays:
    Water level analog gauge
    Analog synchroscope
    APRM 7 Segment display
    Core map (Individual rod full in/full out/overheat)
    Turbine OLED:
        When breaker sync OFF:
            reactor pressure
            turbine RPM
            turbine valve %
            bypass valve %
        When breaker sync ON:
            reactor pressure
            turbine valve %
            electrical demand/load
    Reactor OLED:
        Average position/temperature of selected rods
        Reactor temp
        Recirc valve %
    Cooling OLED:
        Steam flow
        Feedwater flow
        Feedwater valve %

Annunciator lights:
    HIGH RPV LEVEL
    LOW RPV LEVEL
    REACTOR SCRAM
    ROD OVERHEATING
    TURBINE TRIP
    HIGH STEAM PRESSURE

Relations:
    Reactor power:
        ++ Rods position (heavy inertia)
        +++ Recirc (medium inertia)
    Steam flow:
        +++ Reactor power
        + Reactor temp
    Reactor water level:
        +++ Feedwater flow
        --- Steam flow
    Reactor pressure:
        +++ Steam flow
        --- Turbine flow
        -- Bypass flow
    Rod/Reactor temperature:
        +++ Rod position
        ++ Rod fuel level
        + Reactor power
        (reactor temp is avg rods temp)
    Turbine RPM:
        +++ Turbine flow
        (locked at 3600 when breaker sync on)
    Generator load:
        +++ Turbine flow
        ++ Steam pressure

Trip conditions:
    SCRAM:
        Low reactor level
        High reactor pressure
        Rod overheat
        Power upscale
        Manual SCRAM
    Turbine trip:
        High reactor pressure (less than required for SCRAM)
        High reactor level
        Out of phase sync
        Low reactor pressure

Other notes:
    -Phase difference is turbine RPM - 3600, sets rotation speed and direction of synchroscope
    -Breaker sync can only be enabled if synchroscope is top centre and +/- 10 rpm of 3600
    -Each rod is given a fuel value randomly to the player must balance rods