# TechMission

Simulador móvil de gestión de servicios TI para estudiantes de Ingeniería de Sistemas. El estudiante administra el área de TI de una empresa ficticia: recibe incidentes, problemas, solicitudes y cambios, toma decisiones y ve el efecto de cada una sobre los indicadores del área.

Parte del proyecto **Educational Mobile Apps Factory** (aplicación #17 del catálogo maestro).

---

## Qué resuelve

Los estudiantes de Gestión TI aprueban los cursos sabiendo qué dice ITIL, Scrum y PMBOK, pero llegan a su primer trabajo sin haber tomado nunca una decisión de gestión con consecuencias. Este simulador no explica los marcos: los pone en situación. Cada caso obliga a decidir antes de mostrar la explicación, que es lo que convierte el ejercicio en práctica y no en lectura.

| | |
|---|---|
| **Usuario** | Estudiante de Ingeniería de Sistemas, ciclos VII-X, cursos de Gestión de TI, Administración de proyectos y Servicios tecnológicos |
| **Competencias** | Gestión de incidentes, de problemas, de cambios, planificación, priorización y comunicación con interesados |
| **Contenido actual** | 7 módulos, 10 casos empresariales, 43 decisiones, 129 alternativas con retroalimentación |
| **Funciona sin conexión** | Sí, incluida la evaluación y el asistente |

---

## Requisitos

- Flutter 3.24.5 o superior (canal estable)
- JDK 17 para compilar el APK
- Android SDK (Android Studio o `cmdline-tools`)


## Cómo está construido

- **Flutter** con **MVVM** y **Riverpod**. El estado de la simulación vive en un `StateNotifier`; toda la lógica de negocio está en `SimulationEngine`, una clase pura sin dependencias de Flutter, lo que permite probar la evaluación con tests unitarios rápidos.
- **Sin backend**. El contenido son archivos JSON en `assets/`, el progreso se guarda con `shared_preferences`. Un MVP que necesita servidor no se puede repartir en un aula.
- **IA opcional**. El asistente funciona con una base de reglas local; si el estudiante configura una clave de API en Ajustes, pasa a un tutor con modelo de lenguaje que nunca da la respuesta del caso.

```
lib/
├── app/                  tema y widget raíz
├── domain/
│   ├── models/           KPI, competencias, escenarios, progreso
│   ├── engine/           SimulationEngine: lógica pura y evaluación
│   └── services/         asistente (reglas + LLM opcional)
├── data/
│   ├── datasources/      lectura de assets
│   └── repositories/     contenido, progreso, ajustes
└── presentation/
    ├── providers/        inyección de dependencias con Riverpod
    ├── viewmodels/       estado de cada pantalla
    ├── views/            pantallas
    └── widgets/          tablero de KPI, tarjetas de ticket y decisión
assets/data/              contenido educativo en JSON
```
