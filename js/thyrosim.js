"use strict";
//=============================================================================
// FILE:        thyrosim.js
// AUTHOR:      Simon X. Han
// DESCRIPTION:
//   Javascript functions in Thyrosim.
//=============================================================================

//========================================================================
// TASK:    Functions for ajax calls.
//========================================================================

var ThyrosimGraph = new ThyrosimGraph();

//===================================================================
// DESC:    Validate and submit form. Retrieve JSON plotting data and graph.
// ARGS:
//   exp:   An optional experiment
//===================================================================
function ajax_getplot(exp) {

    //---------------------------------------------------------
    // Generate form data for processing server side. For specific experiments,
    // return a predefined string. Otherwise serialize form inputs.
    //---------------------------------------------------------
    var formdata;
    if (exp) {
        formdata = getExperimentStr(exp);
        executeExperiment(exp);
    } else {
        //---------------------------------------------------------
        // Validate form
        //---------------------------------------------------------
        var hasFormError = validateForm();
        if (hasFormError) {
            return false;
        }
        formdata = $('form').serialize();
    }

    //---------------------------------------------------------
    // Submit to server and process response
    //---------------------------------------------------------
    showLoadingMsg();

    var msg;
    var msgColor;
    var time1 = new Date().getTime();
    $.ajaxSetup({timeout:120000}); // No run should take more than 2 mins
    $.post('ajax_getplot.cgi', { data: formdata })
      .done(function( data ) {

        // Graph results from this run
        var rdata = JSON.parse(data); // Run data
        var color = $('input:radio[name=runRadio]:checked').val();
        ThyrosimGraph.setRun(color,rdata);
        graphAll();
        selectRunButton(getNextRunColor());

        msg = '<b>Success!</b> Execution time (sec):';
        msgColor = 'green';
      })
      .fail(function (data ) {
        msg = '<b>Error!</b> Operation timed out (sec):';
        msgColor = 'red';
      })
      .always(function() {
        hideLoadingMsg(); // Hide loading message
        var time2 = new Date().getTime();
        var timeE = Math.floor((time2 - time1)/1000); // Time elapsed
        showOverlayMsg(msg+' '+timeE, msgColor);
      });
}

//========================================================================
// TASK:    Functions for graphing.
//========================================================================

//===================================================================
// DESC:    Wrapper to call the graphing function for each hormone.
//===================================================================
function graphAll() {

    // Need to initialize the graph?
    if (ThyrosimGraph.initGraph) {
        graph("FT4","" ,"1");
        graph("FT3","" ,"1");
        graph("T4" ,"" ,"1");
        graph("T3" ,"" ,"1");
        graph("TSH","1","1");
        ThyrosimGraph.initGraph = false;
    // Plot the graph
    } else {
        graph("FT4","" );
        graph("FT3","" );
        graph("T4" ,"" );
        graph("T3" ,"" );
        graph("TSH","1");
    }
}

//===================================================================
// DESC:    Use d3 to graph a hormone.
// ARGS:
//   hormone:   Hormone name
//   addlabel:  Binary for whether to include x-axis label
//   initgraph: Binary for whether to initialize
//===================================================================
function graph(hormone,addlabel,initgraph) {

    var thysim = $('#thysim').val();
    var comp = ThyrosimGraph.settings[hormone].comp;
    var unit = ThyrosimGraph.settings[hormone].unit;
    var eRLo = ThyrosimGraph.settings[hormone].bounds[thysim].lo;
    var eRHi = ThyrosimGraph.settings[hormone].bounds[thysim].hi;

    // Graph size
    var w = 420; // width in pixels of the graph
    var h = 130; // height in pixels of the graph

    // Scales
    var xVal = ThyrosimGraph.getXVal(comp);
    var yVal = ThyrosimGraph.getYVal(hormone,comp);
    var yEnd = ThyrosimGraph.getEndVal(yVal);
    var x = d3.scale.linear().domain([0,xVal]).range([0,w]);
    var y = d3.scale.linear().domain([0,yEnd]).range([h,0]);

    // Axes - large axes use SI units, ie 1,200 -> 1.2k
    var xAxis = d3.svg.axis().scale(x).orient("bottom")
        .tickSize(-h,0,0);
    var yAxis = d3.svg.axis().scale(y).orient("left")
        .tickSize(-w,0,0);
    if (parseFloat(yEnd) > 1000) {yAxis.tickFormat(d3.format(".2s"));}

    // Default scale is in days, here we create the scales in hours
    var xVal2 = xVal * 24;
    var x2 = d3.scale.linear().domain([0,xVal2]).range([0,w]);
    var xAxis2 = d3.svg.axis().scale(x2).orient("bottom")
        .tickSize(-h,0,0);

    // Graph svg + tooltip
    var graph = d3.select("#"+hormone+"graph");
    var tooltip;
    var f = d3.format(".2f");

    // Initialize the graph
    // Graph is initialized once per instance of loading.
    var xT = 45; // x direction translate
    var yT = 10; // y direction translate
    if (initgraph) {
        tooltip = graph.append("div")
            .attr("class","tooltip")
            .style("opacity",0);

        graph = d3.select("#"+hormone+"graph").append("svg:svg")
            .attr("width",w+60)
            .attr("height",function(d) {return addlabel?h+50:h+20})
          .append("svg:g")
            .attr("transform","translate("+xT+","+yT+")");

        // Add a border around the graph
        var borderPath = graph.append("rect")
            .attr("x",0)
            .attr("y",0)
            .attr("width",w)
            .attr("height",h)
            .attr("shape-rendering","crispEdges")
            .style("stroke","#d7d7d7")
            .style("fill","none")
            .style("stroke-width",2);

        // Add range box here
        var rangeVals = normRangeCalc(yEnd,eRHi,eRLo);
        var rangeBox = graph.append("rect")
            .attr("class","rangeBox")
            .attr("x",0)
            .attr("y",h-y(rangeVals.offset))
            .attr("width",x(xVal))
            .attr("height",h-y(rangeVals.height))
            .attr("shape-rendering","crispEdges")
            .attr("stroke","none")
            .attr("fill","none")
            .style("opacity",0.6);

        // Add title to the side of the graph
        graph.append("text")
            .attr("text-anchor","middle")
            .attr("transform","translate(-30,"+h/2+")rotate(-90)")
            .style("font","16px sans-serif")
            .text(hormone+' '+unit);

        // Add unit to the bottom of the last graph
        if (addlabel) {
            var xT2 = w/2;
            var yT2 = h+30;
            graph.append("text")
                .attr("class","x-axis-label")
                .attr("text-anchor","middle")
                .attr("transform","translate("+xT2+","+yT2+")")
                .style("font","16px sans-serif")
                .text("Days");
        }

        // Add x-axis to graph
        graph.append("svg:g")
            .attr("class","x-axis")
            .attr("stroke","#eee")
            .attr("transform","translate(0,"+h+")")
            .attr("shape-rendering","crispEdges")
            .call(xAxis)
                .selectAll("text")
                .style("display",function(d) {
                    return addlabel?"block":"none";
                });

        // Add y-axis to graph
        graph.append("svg:g")
            .attr("class","y-axis")
            .attr("stroke","#eee")
            .attr("transform","translate(0,0)")
            .attr("shape-rendering","crispEdges")
            .call(yAxis);

        // Add hidden paths to graph
        $.each(ThyrosimGraph.colors,function(color) {
            // Empty data values
            var data = [0];

            // Line
            var line = d3.svg.line()
                .x(function(d,i) {return x(i);})
                .y(function(d,i) {return y(d);});

            // Append dummy line
            graph.append("svg:path")
                .data([data])
                .attr("d",line)
                .attr("class","line"+color)
                .attr("stroke",ThyrosimGraph.getLinecolor(color))
                .attr("stroke-width","2.5")
                .attr("fill","none")
                .style("stroke-dasharray",ThyrosimGraph.getLinestyle(color));

            // Append dummy circle for tooltip
            graph.selectAll("circle.dot"+color)
                .data(data).enter().append("circle")
                .attr("class","dot"+color)
                .attr("fill","none")
                .attr("r",1)
                .attr("cx",function(d,i) {return x(i);})
                .attr("cy",function(d,i) {return y(d);});
        });

        // Turn range values on by default
        togNormRange();

    // Update the graph
    } else {
        // Select tooltip
        tooltip = graph.select("div.tooltip");

        // Update x-axis
        graph.selectAll("g.x-axis")
            .call(xAxis)
                .selectAll("text")
                .style("display",function(d) {
                    return addlabel?"block":"none";
                });

        // Update y-axis
        graph.selectAll("g.y-axis")
            .call(yAxis);

        // Update range box
        var rangeVals = normRangeCalc(yEnd,eRHi,eRLo);
        graph.selectAll("rect.rangeBox")
            .attr("y",h-y(rangeVals.offset))
            .attr("width",x(xVal))
            .attr("height",h-y(rangeVals.height));

        // Update data points for each color
        $.each(ThyrosimGraph.colors,function(color) {
            // Empty data values
            var valuesD = [0];
            var valuesT = [0];

            // Remove old circles
            graph.select("svg").select("g").selectAll(".dot"+color)
                .data(valuesD).exit().remove();

            if (ThyrosimGraph.checkRunColorExist(color)) {
                // Real data values
                valuesD = ThyrosimGraph.getRunValues(color,comp);
                valuesT = ThyrosimGraph.getRunValues(color,"t");
            }

            // Line
            var line = d3.svg.line()
                .x(function(d,i) {return x(valuesT[i]/24);})
                .y(function(d,i) {return y(d);});

            // Update line
            graph.selectAll("path.line"+color)
                .data([valuesD])
                .attr("d",line);

            // Update circles
            // Repeating selection here because d3 doesn't update the old
            // points otherwise.
            var circle = graph
                .select("svg").select("g")
                .selectAll(".dot"+color);

            circle.data(valuesD).enter().append("circle")
                .attr("class","dot"+color)
                .attr("fill","transparent")
                .attr("r",7)
                .attr("cx",function(d,i) {return x(valuesT[i]/24);})
                .attr("cy",function(d,i) {return y(d);})
                .on("mouseover",function(d,i) {
                    var thisX = valuesT[i]/24;
                    var dL = d3.event.pageX+12;
                    var dT = d3.event.pageY;

                    // Bank top/bottom left/right depending on location
                    if (parseFloat(thisX) > parseFloat(0.71*xVal)) {
                        dL = dL - 108;
                    }
                    if (parseFloat(d)     < parseFloat(0.31*yEnd)) {
                        dT = dT - 32;
                    }

                    $(this).attr("fill",color); // Dot color
                    tooltip.transition()
                        .duration(200)
                        .style("opacity",0.8);
                    tooltip.html(hormone+': '+f(d)+'<br>'
                                +'Time: '+f(thisX))
                        .style("left",dL+"px")
                        .style("top", dT+"px");
                })
                .on("mouseout",function(d) {
                    $(this).attr("fill","transparent");
                    tooltip.transition()
                        .duration(500)
                        .style("opacity",0);
                });
        });
    }

    // Toggle range box on and off
    function togNormRange() {
        var rangeBox = d3.selectAll("rect.rangeBox");
        var fill = rangeBox.attr("fill");
        rangeBox.attr("fill",function(d) {
            return fill == "none" ? "yellow" : "none";
        });
    }

    d3.select("#togNormRange").on("click",togNormRange);
}

//===================================================================
// DESC:    Get the next run color.
//===================================================================
function getNextRunColor() {
    var colors = Object.keys(ThyrosimGraph.colors);
    var color = $('input:radio[name=runRadio]:checked').val();
    var i = colors.indexOf(color);
    var j = i + 1;
    if (j >= colors.length) return colors[0];
    return colors[j];
}

//===================================================================
// DESC:    Select the next run button.
//===================================================================
function selectRunButton(color) {
    $('input[name=runRadio]').parent().removeClass('active');
    $('#runRadio'+color).parent().addClass('active');
    $('#runRadio'+color).prop('checked', true);
}

//===================================================================
// DESC:    Show/Hide the loading message box. The +5 offsets the box so that it
//          doesn't interfere with mouse clicks.
//===================================================================
function showLoadingMsg() {
    $(window).click(function(e){
        $('#follow').css('display','block')
                    .css('top',    e.pageY + 5)
                    .css('left',   e.pageX + 5);
    });
    $(window).mousemove(function(e){
        $('#follow').css('display','block')
                    .css('top',    e.pageY + 5)
                    .css('left',   e.pageX + 5);
    });
}
function hideLoadingMsg() {
    $(window).unbind();
    $('#follow').css('display','none');
}

//===================================================================
// DESC:    Generate the overlay message.
// ARGS:
//   html:  Content for $('#overlay-content').html()
//   color: Overlay colorscheme
//===================================================================
function showOverlayMsg(html,color) {
    $('#overlay-content').html(html).attr('class','overlay-'+color);
    $('#overlay').css('display','block');
    $('#overlay-button').focus();
}

//===================================================================
// DESC:    Validate the form. Returns 1 if validation fails.
//===================================================================
function validateForm() {

    $('input[type=text]').removeClass('error'); // Reset

    // Only iterate over text inputs in the form
    var fail = false;
    var maxDay = parseFloat(100.0);
    $.each($("form input[type=text]").serializeArray(), function(i, field) {

        // Get current value and use parseFloat for validation
        field.value = parseFloat($('#'+field.name).val());
        if (!isNaN(field.value)) { // Only overwrite when not NaN
            $('#'+field.name).val(field.value);
        }

        // Check for numeric
        if (/^-?\+?[0-9]*\.?[0-9]+$/.test(field.value) == false) {
            $('#'+field.name).addClass('error');
            fail = true;
        }

        // Check dials for range
        if (/^dialinput(\d+)/.test(field.name)) {
            var num = field.name.match(/^dialinput(\d+)/);
            if (field.value < sliderObj[num[1]].min ||
                field.value > sliderObj[num[1]].max) {
                $('#'+field.name).addClass('error');
                fail = true;
            }
        }

        // 1. Check that start, end, and simtime are <= maxDay
        // 2. Update simtime with the highest start or end day
        if (/^start-/.test(field.name) || /^end-/.test(field.name) ||
            /^simtime/.test(field.name)) {
            if (field.value > maxDay) {
                $('#'+field.name).addClass('error');
                fail = true;
            } else if (field.value > parseFloat($('#simtime').val())) {
                $('#simtime').val(field.value);
            }
        }
    });

    if (fail) showOverlayMsg('<b>Error!</b> Form validation failed.','red');

    return fail;
}

//===================================================================
// DESC:    Get predefined string for a specific experiment.
// ARGS:
//   exp:   The experiment name
//===================================================================
function getExperimentStr(exp) {

    // The default Thyrosim example.
    if (exp == "experiment-default") {
        return "experiment="+exp+"&thysim=Thyrosim";
    }

    // The default ThyrosimJr example.
    if (exp == "experiment-default-jr") {
        return "experiment="+exp+"&thysim=ThyrosimJr";
    }

    // The DiStefano-Jonklaas 2019 Example-1. Only relevant for Thyrosim.
    if (exp == "experiment-DiJo19-1") {
        return "experiment="+exp+"&thysim=Thyrosim";
    }

    return false;
}

//===================================================================
// DESC:    Change the UI to match the experiment ran. When running experiments,
//          clear results and only graph experiment results in Blue.
// ARGS:
//   exp:   The experiment name
//===================================================================
function executeExperiment(exp) {
    $('#input-manager').empty();             // Clear the input space
    ThyrosimGraph.setRun("Green",undefined); // Delete the Green run
    selectRunButton('Blue');                 // Set Blue as exp run

    if (exp == "experiment-default") {
        $('#simtime').val(5);
        tuneDials(100,88,100,88);
    }

    if (exp == "experiment-DiJo19-1") {
        $('#simtime').val(30);
        tuneDials(25,88,25,88);
        addInputOral('T4',123,1,false,1,30);
        addInputOral('T3',6.5,1,false,1,30);
    }

}

//===================================================================
// DESC:    Helper function to change dialinput and slider values.
// ARGS:
//   a:     Dial/Slider 1 value
//   b:     Dial/Slider 2 value
//   c:     Dial/Slider 3 value
//   d:     Dial/Slider 4 value
//===================================================================
function tuneDials(a,b,c,d) {
    $('#dialinput1').val(a); $('#slider1').slider('value',a);
    $('#dialinput2').val(b); $('#slider2').slider('value',b);
    $('#dialinput3').val(c); $('#slider3').slider('value',c);
    $('#dialinput4').val(d); $('#slider4').slider('value',d);
}

//===================================================================
// DESC:    Helper function to add oral inputs.
// ARGS:
//   hormone:   'T4' or 'T3'
//   dose:      Dose
//   interval:  Dosing interval
//   singledose: Whether to use a single dose - true/false value
//   start:     Start time
//   end:       End time
// NOTE:
//   When singledose is true, interval and end can be ''.
//===================================================================
function addInputOral(hormone,dose,interval,singledose,start,end) {
    addInput(hormone+'-Oral');
    var pin = parseInputName($('#input-manager').children().last().attr('id'));
    $('#dose-' + pin[1]).val(dose);
    $('#int-'  + pin[1]).val(interval);
    $('#start-'+ pin[1]).val(start);
    $('#end-'  + pin[1]).val(end);
    if (singledose) {
        $('#singledose-'+pin[1]).prop('checked', true);
        useSingleDose(pin[1]);
    }
}

//===================================================================
// DESC:    Helper function to add IV inputs.
//===================================================================

//===================================================================
// DESC:    Helper function to add infusion inputs.
//===================================================================

//===================================================================
// DESC:    Manages plotting data as Blue or Green plots.
//===================================================================
function ThyrosimGraph() {
    this.initGraph = true;

    // Default color settings. Color order must match button order.
    var colors = {
        Blue:  { linecolor: '#619cff', linestyle: '',
                 rdata: undefined, exist: false },
        Green: { linecolor: '#00ba38', linestyle: '5,3',
                 rdata: undefined, exist: false }
        //Red: { linecolor: '#f8766d'}
    };
    this.colors = colors;

    // Default graph settings
    //   comp:  Comparment name. Server-side data use this name for reference
    //   unit:  Comparment display unit
    //   ymin:  Y-axis value. ymin values are rounded up by a digit. See
    //          getEndVal()
    //   bounds: Normal range
    var settings = {
        FT4: {
            comp: 'ft4',
            unit: 'ng/L',
            ymin: { Thyrosim: 17, ThyrosimJr: 15 },
            bounds: {
                Thyrosim:   { lo: 8,  hi: 17 },
                ThyrosimJr: { lo: 10, hi: 14 }
            }
        },
        FT3: {
            comp: 'ft3',
            unit: 'ng/L',
            ymin: { Thyrosim: 4, ThyrosimJr: 7 },
            bounds: {
                Thyrosim:   { lo: 2.22, hi: 3.83 },
                ThyrosimJr: { lo: 2.32, hi: 7.07 },
            }
        },
        T4: {
            comp: '1',
            unit: '\u03BCg/L', // mcg
            ymin: { Thyrosim: 110, ThyrosimJr: 120 },
            bounds: {
                Thyrosim:   { lo: 45, hi: 105 },
                ThyrosimJr: { lo: 59, hi: 119 },
            }
        },
        T3: {
            comp: '4',
            unit: '\u03BCg/L', // mcg
            ymin: { Thyrosim: 1, ThyrosimJr: 2 },
            bounds: {
                Thyrosim:   { lo: 0.6, hi: 1.8  },
                ThyrosimJr: { lo: 1,   hi: 2.15 },
            }
        },
        TSH: {
            comp: '7',
            unit: 'mU/L',
            ymin: { Thyrosim: 4, ThyrosimJr: 4 },
            bounds: {
                Thyrosim:   { lo: 0.3, hi: 4 },
                ThyrosimJr: { lo: 0.6, hi: 4 },
            }
        },
    };
    this.settings = settings;

    // Set run data
    this.setRun = setRun;
    function setRun(color,rdata) {
        this.colors[color].rdata = rdata;
        if (typeof rdata !== 'undefined') {
            this.colors[color].exist = true;
        } else {
            this.colors[color].exist = false;
        }
    }

    // Get run data's values
    this.getRunValues = getRunValues;
    function getRunValues(color,comp) {
        return this.colors[color].rdata.data[comp].values;
    }

    // Check whether the run data of color exists
    this.checkRunColorExist = checkRunColorExist;
    function checkRunColorExist(color) {
        return this.colors[color].exist;
    }

    // Get the max X value over all colors
    this.getXVal = getXVal;
    function getXVal(comp) {
        var maxX = 0;
        $.each(colors,function(color,o) {
            if (o.exist) {
                if (parseFloat(o.rdata.simTime) > maxX) {
                    maxX = o.rdata.simTime;
                }
            }
        });

        if (maxX) {return maxX;}

        // Default simTime to 5 days
        return "5";
    }

    // Get the max Y value over all colors
    this.getYVal = getYVal;
    function getYVal(hormone,comp) {
        // Retrieve the initial ymin value
        var thysim = $('#thysim').val();
        var maxY = settings[hormone].ymin[thysim];

        $.each(colors,function(color,o) {
            if (o.exist) {
                if (parseFloat(o.rdata.data[comp].max) > maxY) {
                    maxY = o.rdata.data[comp].max;
                }
            }
        });

        return maxY;
    }

    // Get the "End" value by increasing a digit by 1. See the following:
    //   1.1  => 2
    //   1.9  => 3
    //   9.9  => 11
    //   12.1 => 13
    //   20   => 30
    //   90   => 100
    //   99   => 110
    //   100  => 110
    //   500  => 510
    //   900  => 910
    //   1000 => 1100
    //   1100 => 1200
    this.getEndVal = getEndVal;
    function getEndVal(n) {
        var roundRule = 8;
        var num1 = parseInt(n);
        var numL = parseInt(num1.toString().length);
        if (num1 <= 15) { // Grow by 1
            var zero = this.repeat("0",numL-1); // 0
            var mFac = parseInt("1"+zero); // 1
            var numR = this.roundX(n,roundRule);
            numR = numR + 1;
            return numR;
        }
        if (num1 <= 99) {
            var zero = this.repeat("0",numL-1);
            var mFac = parseInt("1"+zero);
            var numR = this.roundX(n/mFac,roundRule)*mFac;
            numR = numR + mFac;
            return numR;
        }
        var zero = this.repeat("0",numL-2);
        var mFac = parseInt("1"+zero);
        var numR = this.roundX(n/mFac,roundRule)*mFac;
        numR = numR + mFac;
        return numR;
    }

    this.getLinestyle = getLinestyle;
    function getLinestyle(color) {
        return this.colors[color].linestyle;
    }

    this.getLinecolor = getLinecolor;
    function getLinecolor(color) {
        return this.colors[color].linecolor;
    }

    // Function to repeat a string. Essentially, "n" x 3 = "nnn".
    this.repeat = repeat;
    function repeat(pattern,count) {
        if (count < 1) return '';
        var returnVal = '';
        while (count > 0) {
            returnVal+=pattern;
            count--;
        }
        return returnVal;
    }

    // Round by certain rules
    // rule can be: 7, 7.5.
    // if 7: 1.7 => 2, 1.69 => 1
    this.roundX = roundX;
    function roundX(n,rule) {
        var n1 = parseFloat(n)*10;
        var nS = n1.toString();
        var nC = parseFloat(nS[1]);
        if (nC >= parseFloat(rule)) return Math.ceil(parseFloat(n));
        return Math.floor(parseFloat(n));
    }
}

//===================================================================
// DESC:    Range box
//===================================================================
function normRangeCalc(yMax,y2,y1) {

    if (y1 > yMax) {
        return { y2: 0, y1: 0, height: 0, offset: 0 };
    }
    if (y2 > yMax) {
        var height = yMax - y1;
        return { y2: yMax, y1: y1, height: height, offset: 0 };
    }

    var height = y2 - y1;
    var offset = yMax - y2;
    return { y2: y2, y1: y1, height: height, offset: offset };
}

//===================================================================
// DESC:    Erase a drawn line
//===================================================================
function resetRun(color) {
    ThyrosimGraph.setRun(color,undefined);
    graphAll();
}

//========================================================================
// TASK:    Functions for UI interactions and animations.
//========================================================================

var animeObj = new animation();

//===================================================================
// DESC:    Create an input and append to footer.
// ARGS:
//   title: Title of the input, e.g., "T4-Oral"
//===================================================================
function addInput(title) {

    var iNum = getNextInputNum();  // Next input number
    var rowN = getRowClass(iNum);  // Next input span row class
    var footer = '#input-manager'; // Input container div id

    // Create a new input span object
    var span = $(document.createElement('span')).attr({id:'input-'+iNum});
    span.addClass(rowN).addClass('input-row');

    //---------------------------------------------------------
    // Append the new input span to the end of footer
    //---------------------------------------------------------
    var pit = parseInputTitle(title);
    if (pit.type == 'Oral')     span.append(    OralInput(pit,iNum));
    if (pit.type == 'IV')       span.append( IVPulseInput(pit,iNum));
    if (pit.type == 'Infusion') span.append(InfusionInput(pit,iNum));
    span.appendTo(footer);

    // Show/Hide animating gifs. 3200 ms because each gif has 8 frames and each
    // frame is 0.4 seconds.
    var aCat = animeObj.getAnimationCat(pit.type);
    var aEle = animeObj.getAnimationEle(pit.type,pit.hormone);
    var id   = animeObj.showAnimation(aCat,aEle);
    setTimeout(function() {animeObj.hideAnimation(aCat,id)},3200);
}

//===================================================================
// DESC:    Generate html for a repeating/single oral dose.
// ARGS:
//   pit:   A parseInputTitle object
//   n:     The input number
//===================================================================
function OralInput(pit,n) {
    return '<div class="container input-subrow">'
         + '  <img src="'+pit.src+'" class="info-icon-m">'
         + '  <span class="inputs" id="label-'+n+'" name="label-'+n+'">'
         + '    Input '+n+' ('+pit.hormone+'-'+pit.type+'):'
         + '  </span>'
         +    addDeleteIcon(n)
         + '</div>'

         + '<div class="container input-subrow">'
         + '  <div class="grid-1-10">'
         +      addOnOff(n)
         + '  </div>'
         + '  <div class="grid-9-10">'
         + '    <span class="floatL">'
         + '      Dose: '
         + '      <input class="inputs oral-dose" type="text"'
         + '             id="dose-'+n+'" name="dose-'+n+'"> &micro;g'
         + '    </span>'
         + '    <span class="floatL mar-l-1em switch">'
         + '      Use Single Dose: '
         + '      <label>'
         + '        <input class="inputs" type="checkbox" value="1"'
         + '               id="singledose-'+n+'" name="singledose-'+n+'"'
         + '               onclick="useSingleDose('+n+');">'
         + '        <span class="lever"></span>'
         + '      </label>'
         + '    </span>'
         + '  </div>'
         + '</div>'

         + '<div class="container input-subrow">'
         + '  <div class="grid-1-10">'
         + '    &nbsp;'
         + '  </div>'
         + '  <div class="grid-9-10">'
         + '    <span class="floatL">'
         + '      Start Day: '
         + '      <input class="inputs" type="text"'
         + '             id="start-'+n+'" name="start-'+n+'">'
         + '    </span>'
         + '    <span class="floatL mar-l-1em">'
         + '      Dosing Interval: '
         + '      <input class="inputs" type="text"'
         + '             id="int-'+n+'" name="int-'+n+'"> Days'
         + '    </span>'
         + '    <span class="floatL mar-l-1em">'
         + '      End Day: '
         + '      <input class="inputs" type="text"'
         + '             id="end-'+n+'" name="end-'+n+'">'
         + '    </span>'
         + '  </div>'
         + '</div>'

         + '<input type="hidden" class="inputs" id="hormone-'+n+'"'
         + '       name="hormone-'+n+'" value="'+pit.hormoneId +'">'
         + '<input type="hidden" class="inputs" id="type-'   +n+'"'
         + '       name="type-'   +n+'" value="'+pit.typeId    +'">'

         + '';
}

//===================================================================
// DESC:    Generate html for an IV pulse dose.
// ARGS:
//   pit:   A parseInputTitle object
//   n:     The input number
//===================================================================
function IVPulseInput(pit,n) {
    return '<div class="container input-subrow">'
         + '  <img src="'+pit.src+'" class="info-icon-m">'
         + '  <span class="inputs" id="label-'+n+'" name="label-'+n+'">'
         + '    Input '+n+' ('+pit.hormone+'-'+pit.type+'):'
         + '  </span>'
         +    addDeleteIcon(n)
         + '</div>'

         + '<div class="container input-subrow">'
         + '  <div class="grid-1-10">'
         +      addOnOff(n)
         + '  </div>'
         + '  <div class="grid-9-10">'
         + '    <span class="floatL">'
         + '      Dose: '
         + '      <input class="inputs" type="text"'
         + '             id="dose-'+n+'" name="dose-'+n+'"> &micro;g'
         + '    </span>'
         + '    <span class="floatL mar-l-1em">'
         + '      Start Day: '
         + '      <input class="inputs" type="text"'
         + '             id="start-'+n+'" name="start-'+n+'">'
         + '    </span>'
         + '  </div>'
         + '</div>'

         + '<input type="hidden" class="inputs" id="hormone-'+n+'"'
         + '       name="hormone-'+n+'" value="'+pit.hormoneId +'">'
         + '<input type="hidden" class="inputs" id="type-'   +n+'"'
         + '       name="type-'   +n+'" value="'+pit.typeId    +'">'

         + '';
}

//===================================================================
// DESC:    Generate html for a constant infusion dose.
// ARGS:
//   pit:   A parseInputTitle object
//   n:     The input number
//===================================================================
function InfusionInput(pit,n) {
    return '<div class="container input-subrow">'
         + '  <img src="'+pit.src+'" class="info-icon-m">'
         + '  <span class="inputs" id="label-'+n+'" name="label-'+n+'">'
         + '    Input '+n+' ('+pit.hormone+'-'+pit.type+'):'
         + '  </span>'
         +    addDeleteIcon(n)
         + '</div>'

         + '<div class="container input-subrow">'
         + '  <div class="grid-1-10">'
         +      addOnOff(n)
         + '  </div>'
         + '  <div class="grid-9-10">'
         + '    <span class="floatL">'
         + '      Dose: '
         + '      <input class="inputs" type="text"'
         + '             id="dose-'+n+'" name="dose-'+n+'"> &micro;g/day'
         + '    </span>'
         + '    <span class="floatL mar-l-1em">'
         + '      Start Day: '
         + '      <input class="inputs" type="text"'
         + '             id="start-'+n+'" name="start-'+n+'">'
         + '    </span>'
         + '    <span class="floatL mar-l-1em">'
         + '      End Day: '
         + '      <input class="inputs" type="text"'
         + '             id="end-'+n+'" name="end-'+n+'">'
         + '    </span>'
         + '  </div>'
         + '</div>'

         + '<input type="hidden" class="inputs" id="hormone-'+n+'"'
         + '       name="hormone-'+n+'" value="'+pit.hormoneId +'">'
         + '<input type="hidden" class="inputs" id="type-'   +n+'"'
         + '       name="type-'   +n+'" value="'+pit.typeId    +'">'

         + '';
}

//===================================================================
// DESC:    Delete an input and rename remaining input ids to be continuous.
// ARGS:
//   n:     The input number
//===================================================================
function deleteInput(n) {

    n = parseInt(n); // Treat as integer

    // Get the number of inputs before this deletion
    var end = $('#input-manager').children().length;

    // Delete the input element
    $('#input-'+n).remove();

    //---------------------------------------------------------
    // Outer loop.
    // Loop through all inputs whose n > the deleted one's
    //---------------------------------------------------------
    for (var i = n + 1; i <= end; i++) {

        var j = parseInt(i-1); // New num

        //---------------------------------------------------------
        // Inner loop.
        // Loop through the descendants of an input-row. Find descendants with
        // class 'inputs' and rename attributes: id, name.
        //---------------------------------------------------------
        $('#input-'+i).find('.inputs').each(function() {
            var child = $(this);

            // Rename by subtracting the number by one, ie:
            // input-3 => input-2
            var pin = parseInputName(child.attr('name'));
            child.attr('id'  ,pin[0]+'-'+j);
            child.attr('name',pin[0]+'-'+j);

            //---------------------------------------------------------
            // By this point, ids and names of elements have been renamed, but a
            // few special cases remain.
            //---------------------------------------------------------

            // The element with name 'label-X' contains a brief description of
            // what this input is. Change text that says 'Input X (type)'
            if (child.attr('name').match(/label/)) {
                child.text(child.text().replace(/Input \d+/,'Input '+j));
            }

            // The element with id/name 'enabled-X' or 'singledose-X' contain a
            // javascript argument that need to be changed.
            if (child.attr('name').match(/enabled|singledose/)) {
                child.attr('onclick',child.attr('onclick').replace(/\d+/,j));
            }

            // The delete button has name 'delete-X'. Change the javascript
            // argument in name 'href'.
            if (child.attr('name').match(/delete/)) {
                child.attr('href',child.attr('href').replace(/\d+/,j));
            }
        }); // Inner loop end.

        // Change the row colors
        $('#input-'+i).removeClass('row0 row1');
        $('#input-'+i).addClass(getRowClass(j));

        // Rename the input-row's span id at the end
        $('#input-'+i).attr('id','input-'+j);

    } // Outer loop end.
}

//===================================================================
// DESC:    Given an input id/name, parse it and build an object.
// ARGS:
//   name:  Input id/name, e.g., "label-1"
// NOTE:    Return object customarily called 'pin'.
//===================================================================
function parseInputName(name) {
    return name.split("-");
}

//===================================================================
// DESC:    Given an input title, parse it and build an object.
// ARGS:
//   title: Input title, e.g., "T4-Oral"
// NOTE:    Return object customarily called 'pit'.
//===================================================================
function parseInputTitle(title) {
    var split = title.split("-");
    var o = {
        hormone:   split[0],                 // T4 or T3
        hormoneId: split[0].replace("T",""), // 4 or 3
        type:      split[1],                 // Oral/IV/Infusion
        typeId:    getInputTypeId(split[1]), // See the function
        src:       getInputImgSrc(title)     // Image src
    };
    return o;
}

//===================================================================
// DESC:    Given an input type, return corresponding type id.
// ARGS:
//   type:  Input type, e.g., Oral/IV/Infusion
//===================================================================
function getInputTypeId(type) {
    if (type == "Oral")     return 1;
    if (type == "IV")       return 2;
    if (type == "Infusion") return 3;
}

//===================================================================
// DESC:    Given an input title, return image source.
// ARGS:
//   title: Input title, e.g., "T4-Oral"
//===================================================================
function getInputImgSrc(title) {
    if (title == "T3-Oral")     return '../img/pill1.png';
    if (title == "T3-IV")       return '../img/syringe1.png';
    if (title == "T3-Infusion") return '../img/infusion1.png';
    if (title == "T4-Oral")     return '../img/pill2.png';
    if (title == "T4-IV")       return '../img/syringe2.png';
    if (title == "T4-Infusion") return '../img/infusion2.png';
}

//===================================================================
// DESC:    Count the number of input spans and add 1. This is the number the
//          next input should have. Input numbers start at 1.
//===================================================================
function getNextInputNum() {
    return $("#input-manager").children().length + 1;
}

//===================================================================
// DESC:    Determine row color based on position.
// ARGS:
//   n:     A number indicating the element is in the nth position
//===================================================================
function getRowClass(n) {
    return 'row' + n % 2;
}

//===================================================================
// DESC:    Add a clickable toggle on/off input button. The button initializes
//          as ON. A hidden input named "disabled-X" is used to store whether
//          the input is ON/OFF. Value of 1 means OFF and value of 0 means ON.
// ARGS:
//   n:     The input number
//===================================================================
function addOnOff(n) {
    return '<span alt="Turn input off" class="floatL tog-in tog-in-1 inputs"'
         + '      id="enabled-'+n+'" name="enabled-'+n+'"'
         + '      onclick="togInput('+n+');">'
         + 'ON'
         + '</span>'
         + '    '
         + '<input type="hidden" class="inputs" id="disabled-'+n+'"'
         + '       name="disabled-'+n+'" value="0">'
         + '';
}

//===================================================================
// DESC:    Add x.png so that it can be used to delete an input.
// ARGS:
//   n:     The input number
//===================================================================
function addDeleteIcon(n) {
    return '<a class="img-input inputs"'
         + '   name="delete-'+n+'" href="javascript:deleteInput('+n+');">'
         + '  <img class="floatR info-icon-m"'
         + '       src="../img/x.png" alt="Delete this input">'
         + '</a>'
         + '';
}

//===================================================================
// DESC:    Detect value in element enabled-X/disabled-X and change them:
//          1. When input is enabled
//            a. "enabled-X"'s text changes to "disabled"
//            b. "disabled-X"'s value changes to 1
//          2. When input is disabled: opposite of the above
// ARGS:
//   n:     The input number
//===================================================================
function togInput(n) {
    var ena = $('#enabled-' +n);
    var dis = $('#disabled-'+n);
    // Turn input off
    if (ena.hasClass('tog-in-1')) {
        ena.removeClass('tog-in-1').addClass('tog-in-2');
        ena.attr('alt','Turn input on');
        ena.text('OFF');
        dis.attr('value','1');
        // Gray out this input's other input boxes
        $('#input-'+n).find('.inputs').each(function() {
            $(this).attr('disabled',true);
        });
    // Turn input on
    } else {
        ena.removeClass('tog-in-2').addClass('tog-in-1');
        ena.attr('alt','Turn input off');
        ena.text('ON');
        dis.attr('value','0');
        // Un-gray out this input's other input boxes
        $('#input-'+n).find('.inputs').each(function() {
            var child = $(this);
            // Remove the 'disabled' attribute unless "Single Dose" is checked
            var sd = $('input[name="singledose-'+n+'"]:checked').length > 0;
            if ((sd && (child.attr('id') == 'int-'+n)) ||
                (sd && (child.attr('id') == 'end-'+n)) ) {
                // Do nothing here
            } else {
                child.attr('disabled',false);
            }
        });
    }
}

//===================================================================
// DESC:    Tell the oral input to use only a single dose. In addition:
//          1. Gray out the "Dosing Interval" and "End Day" inputs.
//          2. Fill "Dosing Interval" and "End Day" with a "0" if blank.
// ARGS:
//   n:     The input number
//===================================================================
function useSingleDose(n) {
    var isChecked = $('input[name="singledose-'+n+'"]:checked').length > 0;
    var endE = $('#end-'+n); // E for element
    var intE = $('#int-'+n);
    if (isChecked) {
        endE.prop('disabled',true); // Gray out input boxes
        intE.prop('disabled',true);
        if (!endE.attr('value')) endE.attr('value','0'); // Fill with 0
        if (!intE.attr('value')) intE.attr('value','0');
    } else {
        endE.prop('disabled',false);
        intE.prop('disabled',false);
    }
}

//===================================================================
// DESC:    Show/Hide the scrollbars for secretion/absorption adjustment.
//===================================================================
function togScrollBars() {
    $('.sliders').toggle("blind", {direction:"left"}, function() {
        if ($('.sliders').css('display') == 'none') {
            $('#scrollbar').attr('src','../img/plus.png')
                           .attr('alt','Show scrollbars');
        } else {
            $('#scrollbar').attr('src','../img/minus.png')
                           .attr('alt','Hide scrollbars');
        }
    });
}

//===================================================================
// DESC:    Animation manager.
//===================================================================
function animation() {

    // Define animation element ids based on hormone and type here
    // hormones: T3/T4, types: Oral/IV/Infusion, cat: category
    var element = {
        Oral:     { T3: 'spill1',  T4: 'spill2',  cat: 'spill'  },
        IV:       { T3: 'inject1', T4: 'inject2', cat: 'inject' },
        Infusion: { T3: 'infuse1', T4: 'infuse2', cat: 'infuse' }
    };
    this.element = element;

    //---------------------------------------------------------
    // 1. Create a container div and append an image (animation) in it. Then,
    //    append the container div to #diagram.
    // 2. The image src has a '?+id', this is so browsers are forced to reload
    //    the image. Otherwise, the browser uses a cached image and the
    //    animation will appear out of sync.
    // 3. Animation positions are defined in thyrosim.css under the category's
    //    name.
    //---------------------------------------------------------
    this.showAnimation = showAnimation;
    function showAnimation(cat,ele) {
        var id = new Date().getTime().toString();
        $('<div>').attr({'id':cat+'-'+id,'class':cat}).html(
        $('<img>').attr({'id':cat+'img-'+id,'src':'../img/'+ele+'.gif?'+id}))
        .appendTo('#img-param');
        return id;
    }

    //---------------------------------------------------------
    // Remove the container div ('hiding' the image)
    //---------------------------------------------------------
    this.hideAnimation = hideAnimation;
    function hideAnimation(cat,id) {
        $('#'+cat+'-'+id).remove();
    }

    //---------------------------------------------------------
    // For a given hormone and input type, get the file name
    //---------------------------------------------------------
    this.getAnimationEle = getAnimationEle;
    function getAnimationEle(type,hormone) {
        return this.element[type][hormone];
    }

    //---------------------------------------------------------
    // Get the animation category for the input type
    //---------------------------------------------------------
    this.getAnimationCat = getAnimationCat;
    function getAnimationCat(type) {
        return this.element[type]['cat'];
    }
}

//===================================================================
// DESC:    Define sliders and tie slider values to dial input values.
//          1: T4 Secretion
//          2: T4 Absorption
//          3: T3 Secretion
//          4: T3 Absorption
//===================================================================
var sliderObj = {
    '1':{'min':0,'max':125,'value':100,'range':'min','animate':'fast'},
    '2':{'min':0,'max':100,'value':88, 'range':'min','animate':'fast'},
    '3':{'min':0,'max':125,'value':100,'range':'min','animate':'fast'},
    '4':{'min':0,'max':100,'value':88, 'range':'min','animate':'fast'}
};

//===================================================================
// DESC:    Function to show/hide an id. Takes an optional time argument.
// NOTE:    ms cannot be 0; use 1 for shortest possible toggle.
//===================================================================
function toggle(id,ms) {
    $('#'+id).toggle('blind',ms);
}

//===================================================================
// DESC:    Function to show/hide a hormone menu.
//===================================================================
function togHormoneMenu(id) {
    $('#'+id).toggle('blind');
    $('#'+id+'-head > button > i').toggleClass('arrow-d arrow-u');
}

//===================================================================
// DESC:    Function to show/hide header info.
//===================================================================
function togInfoBtn(id) {
    if ($('#info-btn-c-'+id).css('display') == 'none') { // Open
        // Close any open info buttons
        $.each($('.info-btn-c'), function() {
            if ($(this).css('display') !== 'none') {
                $(this).toggle('blind',200,function() {
                    $(this).siblings('button').toggleClass('info-btn-a',0);
                });
            }
        });
        // Open the clicked one
        $('#info-btn-'+id).toggleClass('info-btn-a',0,function() {
            $('#info-btn-c-'+id).toggle('blind',200);
        });
    } else { // Close
        $('#info-btn-c-'+id).toggle('blind',200,function() {
            $('#info-btn-'+id).toggleClass('info-btn-a',0);
        });
    }
}

//===================================================================
// DESC:    Function to toggle free hormone graph divs.
//===================================================================
function togFreeHormone() {
    $('#FT4graph').toggleClass('show hide');
    $('#FT3graph').toggleClass('show hide');
    $('#T4graph').toggleClass('show hide');
    $('#T3graph').toggleClass('show hide');
}

//===================================================================
// DESC:    Function to convert parameters to JSON string.
//===================================================================
function saveParams() {
    var obj = {};
    $.each($("#parameters input[type=text]"), function(i, field) {
        obj[field.name] = field.value;
    });
    $("#paramtextarea").val(JSON.stringify(obj));
}

//===================================================================
// DESC:    Function to update parameters from a JSON string.
//===================================================================
function loadParams() {
    var val = $("#paramtextarea").val();
    if (val) { // Ignore empty/null strings
        var obj = JSON.parse(val);
        if (obj && typeof obj === "object") {
            $.each(obj, function(key, value) {
                $("#parameters #"+key).val(value);
            });
        }
    }
}

//===================================================================
// DESC:    jQuery $(document).ready() functions.
//===================================================================
$(function() {

    // Initialize D3 charts
    graphAll();

    // Initialize jQuery UI tooltip
    $(document).tooltip({
        tooltipClass: "thysim-tooltip"
    });

    // Initialize slider objects
    $.each(sliderObj,function(k,o) {
        var s = '#slider'+k;
        var d = '#dialinput'+k;
        $(s).slider({
            min:     o.min,
            max:     o.max,
            value:   o.value,
            range:   o.range,
            animate: o.animate,
            // Change dialinput's value to match slider's value
            slide:   function(event,ui) { $(d).val(ui.value); }
        });
        // Set defaultValue property
        $(d).prop('defaultValue',$(s).slider('value'));
        // Changes slider value when changing dialinput
        $(d).keyup(function() {
            $(s).slider('value',this.value);
        });
    });

    // Initialize button groups. Apply an "active" class on the checked input.
    // Require the following construction:
    // <span/div class="btn-group">
    //   <label class="btn btn-$color">
    //     <input type="radio" name="myradio" id="r1" value="1">1
    //   </label>
    //   <label class="btn btn-$color">
    //     <input type="radio" name="myradio" id="r2" value="2">2
    //   </label>
    //   <label class="btn btn-$color">
    //     <input type="radio" name="myradio" id="r3" value="3">3
    //   </label>
    $.each($('.btn-group > label'),function() {
        var label = $(this);
        label.click(function() {
            label.addClass('active');
            label.children('input').prop('checked',true);
            label.siblings().removeClass('active');
        });
    });

    // Initialize "Next Run" as Blue
    selectRunButton('Blue');

}); // jQuery $(document).ready() functions end

//===================================================================
// Section
//===================================================================
//---------------------------------------------------------
// Sub-section
//---------------------------------------------------------

