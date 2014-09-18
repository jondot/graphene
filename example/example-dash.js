(function() {
  var description;
  description = {
    "Total Notifications": {
      source: "http://localhost:4567/",
      GaugeLabel: {
        parent: "#hero-one",
        observer: function(data){
          console.log("Label observing " + data);
        },
        title: "Notifications Served",
        type: "max"
      }
    },
    "Poll Time": {
      source: "http://localhost:4567/",
      GaugeGadget: {
        parent: "#hero-one",
        title: "P1",
        observer: function(data){
          console.log("Gadget observing " +data);
        }
      }
    },
    "CPU": {
      source: "http://localhost:4567/",
      ProgressBarGadget: {
        parent: "#hero-one",
        title: "CPU",
        to: 1000,
        unit: "%",
        observer: function(data){
          console.log("Progress observing " +data);
        }
      }
    },
   

    "Total Installs": {
      source: "http://localhost:4567/",
      GaugeLabel: {
        parent: "#hero-three",
        title: "Clients Installed"
      }
    },
    "Clients 1": {
      source: "http://localhost:4567/",
      GaugeGadget: {
        parent: "#hero-three",
        title: "Cl1"
      }
    },
    "CTR": {
      source: "http://localhost:4567/",
      ProgressBarGadget: {
        parent: "#hero-three",
        title: "CTR",
        to: 1000,
        unit: "%",
        observer: function(data){
          console.log("Progress observing " +data);
        }
      }
    },
      
    "New Message": {
      source: "http://localhost:4567/",
      TimeSeries: {
        parent: '#g1-1',
        title: 'New Message',
        label_offset: 200, 
        label_columns: 2,
        time_span_mins: 12,
        observer: function(data){
          console.log("Time series observing ", data);
        }
      }
    },
    "Feed Poll": {
      source: "http://localhost:4567/",
      TimeSeries: {
        title: 'Feed Poll',
        y_ticks: 2,
        display_verticals: true,
        parent: '#g1-2'
      }
    },
    "Topics": {
      source: "http://localhost:4567/",
      refresh_interval: 20000,
      TimeSeries: {
        title: 'Topics',
        parent: '#g1-3'
      }
    },
    "Queue Push": {
      source: "http://localhost:4567/",
      TimeSeries: {
        title: 'Queue Push',
        ymax: 1000,
        warn: 600,
        error: 800,
        parent: '#g2-1'
      }
    },
    "Queue Work": {
      source: "http://localhost:4567/",
      TimeSeries: {
        parent: '#g2-2'
      }
    },
    "Foo Work": {
      source: "http://localhost:4567/",
      BarChart: {
        parent: '#g2-3'
      }
    }
  };


  var g = new Graphene;
  g.demo();
  g.build(description);


}).call(this);
