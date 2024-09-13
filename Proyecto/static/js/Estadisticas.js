function Estadisticas(seleccion){
    switch(seleccion){
        case "VM":
            document.getElementById("valorF").innerHTML='<input type="month" id="fecha"><a href="#" onclick="VentaMes()"><i class="fa fa-check-square fa-lg" aria-hidden="true"></i></a>';
            document.getElementById("pagination").innerHTML=`<li class="page-item active" id=""><a class="page-link" href="#">Ventas Mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('VS')">Ventas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CM')">Compras mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CS')">Compras Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTS')">Horas Trabajadas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTM')">Horas Trabajadas Mes</a></li>`;
            
            VentaMes();
            break;
        case "VS":
            document.getElementById("valorF").innerHTML='<input type="week" id="fecha"><a href="#" onclick="VentaSem()"><i class="fa fa-check-square fa-lg" aria-hidden="true"></i></a>';
            document.getElementById("pagination").innerHTML=`<li class="page-item" id=""><a class="page-link" href="#" onclick="Estadisticas('VM')">Ventas Mes</a></li>
            <li class="page-item active"><a class="page-link" href="#" >Ventas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CM')">Compras mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CS')">Compras Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTS')">Horas Trabajadas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTM')">Horas Trabajadas Mes</a></li>`;
            VentaSem();
            break;
        case "CM":
            document.getElementById("valorF").innerHTML='<input type="month" id="fecha"><a href="#" onclick="CompraMes()"><i class="fa fa-check-square fa-lg" aria-hidden="true"></i></a>';
            document.getElementById("pagination").innerHTML=`<li class="page-item" id=""><a class="page-link" href="#" onclick="Estadisticas('VM')">Ventas Mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('VS')">Ventas Semana</a></li>
            <li class="page-item active"><a class="page-link" href="#">Compras mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CS')">Compras Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTS')">Horas Trabajadas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTM')">Horas Trabajadas Mes</a></li>`;
            CompraMes();
            break;
        case "CS":
            document.getElementById("valorF").innerHTML='<input type="week" id="fecha"><a href="#" onclick="CompraSem()"><i class="fa fa-check-square fa-lg" aria-hidden="true"></i></a>';
            document.getElementById("pagination").innerHTML=`<li class="page-item" id=""><a class="page-link" href="#" onclick="Estadisticas('VM')">Ventas Mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('VS')">Ventas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CM')">Compras mes</a></li>
            <li class="page-item active"><a class="page-link" href="#">Compras Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTS')">Horas Trabajadas Semanas</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTM')">Horas Trabajadas Mes</a></li>`;
            CompraSem();
            break;
        case "HTS":
            document.getElementById("valorF").innerHTML='<input type="week" id="fecha"><a href="#" onclick="usuariosem()"><i class="fa fa-check-square fa-lg" aria-hidden="true"></i></a>';
            document.getElementById("pagination").innerHTML=`<li class="page-item" id=""><a class="page-link" href="#" onclick="Estadisticas('VM')">Ventas Mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('VS')">Ventas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CM')">Compras mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CS')">Compras Semana</a></li>
            <li class="page-item active"><a class="page-link" href="#">Horas Trabajadas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTM')">Horas Trabajadas Mes</a></li>`;
            usuariosem();
            break;
         case "HTM":
            document.getElementById("valorF").innerHTML='<input type="month" id="fecha"><a href="#" onclick="usuariomes()"><i class="fa fa-check-square fa-lg" aria-hidden="true"></i></a>';
            document.getElementById("pagination").innerHTML=`<li class="page-item" id=""><a class="page-link" href="#" onclick="Estadisticas('VM')">Ventas Mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('VS')">Ventas Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CM')">Compras mes</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('CS')">Compras Semana</a></li>
            <li class="page-item"><a class="page-link" href="#" onclick="Estadisticas('HTS')">Horas Trabajadas Semana</a></li>
            <li class="page-item active"><a class="page-link" href="#">Horas Trabajadas Mes</a></li>`;
            usuariomes();
            break;
        
        
        
        

    }
}
function VentaMes(){
    mes=document.getElementById("fecha").value;
    if (!mes){
        var url1='/productovmes_API/0';
    }else{
        var url1='/productovmes_API/'+mes;
    }
    fetch(url1)
    .then(data=>data.json())
    .then(data=>{
    const $grafica = document.querySelector("#grafica1");
    // Las etiquetas son las que van en el eje X.
    const etiquetas = [""+data.producto0[1]+"",""+data.producto2[1]+"",""+data.producto1[1]+""]
    // Podemos tener varios conjuntos de datos. Comencemos con uno
    const datosVentasM = {
        label: "Ventas del Mes",
        data: [data.producto0[0],data.producto2[0],data.producto1[0],0,0], // La data es un arreglo que debe tener la misma cantidad de valores que la cantidad de etiquetas
        backgroundColor: 'hsla(192, 59%, 51%, 0.377)', // Color de fondo
        borderColor: 'rgba(54, 162, 235, 1)', // Color del borde
        borderWidth: 3,// Ancho del borde
    };
    new Chart($grafica, {
        type: 'line',// Tipo de gráfica
        data: {
            labels: etiquetas,
            datasets: [
                datosVentasM,
                // Aquí más datos...
            ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    }
                }],
            },
        }
    });
    })
}
function VentaSem(){
    semana=document.getElementById("fecha").value;
    if (!semana){
        var url2="/productovsem_API/0";
    }else
        var url2="/productovsem_API/"+semana;
    fetch(url2)
    .then(data=>data.json())
    .then(data=>{
    const $grafica = document.querySelector("#grafica1");
    // Las etiquetas son las que van en el eje X.
    const etiquetas = [""+data.producto0[1]+"",""+data.producto2[1]+"",""+data.producto1[1]+""]
    // Podemos tener varios conjuntos de datos. Comencemos con uno
    const datosVentasS = {
        label: "Ventas de la semana",
        data: [data.producto0[0],data.producto2[0],data.producto1[0],0,0], // La data es un arreglo que debe tener la misma cantidad de valores que la cantidad de etiquetas
        backgroundColor: 'hsla(275, 71%, 60%, 0.377)', // Color de fondo
        borderColor: 'rgb(151, 0, 255)', // Color del borde
        borderWidth: 3,// Ancho del borde
    };
    new Chart($grafica, {
        type: 'line',// Tipo de gráfica
        data: {
            labels: etiquetas,
            datasets: [
                datosVentasS,
                // Aquí más datos...
            ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    }
                }],
            },
        }
    });
    })
    }

function CompraMes(){
    mes=document.getElementById("fecha").value;
    if (!mes){
        var url1='/productocmes_API/0';
    }else{
        var url1='/productocmes_API/'+mes;
    }
    fetch(url1)
    .then(data=>data.json())
    .then(data=>{
    const $grafica = document.querySelector("#grafica1");
    // Las etiquetas son las que van en el eje X.
    const etiquetas = [""+data.producto0[1]+"",""+data.producto2[1]+"",""+data.producto1[1]+""]
    // Podemos tener varios conjuntos de datos. Comencemos con uno
    const datosVentasM = {
        label: "Compras del Mes",
        data: [data.producto0[0],data.producto2[0],data.producto1[0],0,0], // La data es un arreglo que debe tener la misma cantidad de valores que la cantidad de etiquetas
        backgroundColor: 'hsla(109, 58%, 61%, 0.377)', // Color de fondo
        borderColor: 'rgba(48, 240, 5, 1)', // Color del borde
        borderWidth: 3,// Ancho del borde
    };
    new Chart($grafica, {
        type: 'line',// Tipo de gráfica
        data: {
            labels: etiquetas,
            datasets: [
                datosVentasM,
                // Aquí más datos...
            ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    }
                }],
            },
        }
    });
    })
}

function CompraSem(){
semana=document.getElementById("fecha").value;
if (!semana){
    var url2="/productocsem_API/0";
}else
    var url2="/productocsem_API/"+semana;
fetch(url2)
.then(data=>data.json())
.then(data=>{
const $grafica = document.querySelector("#grafica1");
// Las etiquetas son las que van en el eje X.
const etiquetas = [""+data.producto0[1]+"",""+data.producto2[1]+"",""+data.producto1[1]+""]
// Podemos tener varios conjuntos de datos. Comencemos con uno
const datosVentasS = {
    label: "Compras de la semana",
    data: [data.producto0[0],data.producto2[0],data.producto1[0],0,0], // La data es un arreglo que debe tener la misma cantidad de valores que la cantidad de etiquetas
    backgroundColor: 'hsla(158, 72%, 59%, 0.377)', // Color de fondo
    borderColor: 'hsl(158, 100%, 50%)', // Color del borde
    borderWidth: 3,// Ancho del borde
};
new Chart($grafica, {
    type: 'line',// Tipo de gráfica
    data: {
        labels: etiquetas,
        datasets: [
            datosVentasS,
            // Aquí más datos...
        ]
    },
    options: {
        scales: {
            yAxes: [{
                ticks: {
                    beginAtZero: true
                }
            }],
        },
    }
});
})
}

function usuariosem(){
    function timeToMinutes(horas) {
        const parts = horas.split(':');
        const hours = parseInt(parts[0]);
        const minutes = parseInt(parts[1]);
        return (String(hours)+"."+String(minutes));}
    semana=document.getElementById("fecha").value;
    if (!semana){
        var url1='/trabajadorsem_API/0';
    }else{
        var url1='/trabajadorsem_API/'+semana;
    }
    fetch(url1)
    .then(data=>data.json())
    .then(data=>{
    const horas=[
        timeToMinutes(data.usuario0[0]),
        timeToMinutes(data.usuario2[0]),
        timeToMinutes(data.usuario1[0])
    ]
    const nombres=[
        (""+data.usuario0[1]+" "+data.usuario0[2]+" "+data.usuario0[3]+""),
        (""+data.usuario2[1]+" "+data.usuario2[2]+" "+data.usuario2[3]+""),
        (""+data.usuario1[1]+" "+data.usuario1[2]+" "+data.usuario1[3]+"")
    ]
    const $grafica = document.querySelector("#grafica1");
    // Las etiquetas son las que van en el eje X.
    const etiquetas = [nombres[0],nombres[1],nombres[2]]
    // Podemos tener varios conjuntos de datos. Comencemos con uno
    
    const datosusariosemantra = {
        label: "trabajador",
        data: [horas[0],horas[1],horas[2]], // La data es un arreglo que debe tener la misma cantidad de valores que la cantidad de etiquetas
        backgroundColor: 'hsla(135, 69%, 46%, 0.377)', // Color de fondo
        borderColor: 'rgba(55, 177, 87, 1)', // Color del borde
        borderWidth: 3,// Ancho del borde
    };
    new Chart($grafica, {
        type: 'bar',// Tipo de gráfica
        data: {
            labels: etiquetas,
            datasets: [
                datosusariosemantra,
                // Aquí más datos...
            ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    },
                    scaleLabel: { // titulo en y
                        display: true, // Mostrar el título
                        labelString: 'Horas . Minutos', // El texto del título
                        fontSize: 16, // Tamaño 
                        fontColor: '#000', // Color 
                        fontFamily:"Corbel",//tipo de letras
                    }
                }]
            },
        }
    });
    })
}
function usuariomes(){
    function timeToMinutes(horas) {
        const parts = horas.split(':');
        const hours = parseInt(parts[0]);
        const minutes = parseInt(parts[1]);
        return (String(hours)+"."+String(minutes));}
    mes=document.getElementById("fecha").value;
    if (!mes){
        var url1='/trabajadormes_API/0';
    }else{
        var url1='/trabajadormes_API/'+mes;
    }
    fetch(url1)
    .then(data=>data.json())
    .then(data=>{
    const horas=[
        timeToMinutes(data.usuario0[0]),
        timeToMinutes(data.usuario2[0]),
        timeToMinutes(data.usuario1[0])
    ]
    const nombres=[
        (""+data.usuario0[1]+" "+data.usuario0[2]+" "+data.usuario0[3]+""),
        (""+data.usuario2[1]+" "+data.usuario2[2]+" "+data.usuario2[3]+""),
        (""+data.usuario1[1]+" "+data.usuario1[2]+" "+data.usuario1[3]+"")
    ]
    const $grafica = document.querySelector("#grafica1");
    // Las etiquetas son las que van en el eje X.
    const etiquetas = [nombres[0],nombres[1],nombres[2]]
    // Podemos tener varios conjuntos de datos. Comencemos con uno
    
    const datosusariosemantra = {
        label: "trabajador",
        data: [horas[0],horas[1],horas[2]], // La data es un arreglo que debe tener la misma cantidad de valores que la cantidad de etiquetas
        backgroundColor: 'hsla(242, 69%, 46%, 0.377)', // Color de fondo
        borderColor: 'rgba(59, 55, 177 , 1)', // Color del borde
        borderWidth: 3,// Ancho del borde
    };
    new Chart($grafica, {
        type: 'bar',// Tipo de gráfica
        data: {
            labels: etiquetas,
            datasets: [
                datosusariosemantra,
                // Aquí más datos...
            ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    },
                    scaleLabel: { // titulo en y
                        display: true, // Mostrar el título
                        labelString: 'Horas . Minutos', // El texto del título
                        fontSize: 16, // Tamaño 
                        fontColor: '#000', // Color 
                        fontFamily:"Corbel",//tipo de letras
                    }
                }]
            },
        }
    });
    })
}