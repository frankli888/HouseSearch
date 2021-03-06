<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>租房搜索</title>
    <link rel="shortcut icon" href="../icon/favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" href="https://cdn.bootcss.com/bootstrap/3.3.7/css/bootstrap.min.css"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <link rel="stylesheet" href="http://cache.amap.com/lbs/static/main1119.css"/>
    <link rel="stylesheet" href="http://cache.amap.com/lbs/static/jquery.range.css"/>
    <script src="http://webapi.amap.com/maps?v=1.3&key=8a971a2f88a0ec7458d43b8bc03b6462&plugin=AMap.ArrivalRange,AMap.Scale,AMap.Geocoder,AMap.Transfer,AMap.Autocomplete,AMap.CitySearch,AMap.Walking"></script>
    <script src="https://cdn.bootcss.com/jquery/3.2.1/jquery.js"></script>
    <script src="https://cdn.bootcss.com/bootstrap/3.3.7/js/bootstrap.min.js"
            integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
            crossorigin="anonymous"></script>
    <style type="text/css">
        .col-md-4 {
            font-size: 20px;
            font-family: "微软雅黑";
        }
    </style>
</head>
<body>
<div class="container">
    <div id="container" clss="col-md-10">
    </div>
    <div class="col-md-4 col-md-offset-9">
        <div class="row form-group">
            <label>当前城市：</label>
            <label id="city">北京市</label>
        </div>
        <div class="row form-group">
            <label>最低价格</label>
            <input id="minprice" class="form-control"/>
        </div>
        <div class="row form-group">
            <label>最高价格</label>
            <input id="maxprice" class="form-control"/>
        </div>
        <div class="row form-group">
            <label>面积</label>
            <select id="area" class="form-control">
                <option value="">请选择</option>
                <option value="&area=0_10">10m²以下</option>
                <option value="&area=10_30">10-30m²</option>
                <option value="&area=30_50">30-50m²</option>
                <option value="&area=50_70">50-70m²</option>
                <option value="&area=70_90">70-90m²</option>
                <option value="&area=90_300">90m²以上</option>
            </select>
        </div>
        <div class="row form-group">
            <label>靠近地铁</label>
            <select id="subway" class="form-control">
                <option value="">否</option>
                <option value="&pagetype=sub">是</option>
            </select>
        </div>
        <div class="row form-group">
            <button class="btn btn-primary" onclick="btnClick()">搜索</button>
        </div>
    </div>
</div>
</body>
<script>
    var cityCode;
    var temp = "010";

    //加载地图
    var map = new AMap.Map('container', {
        zoom: 11,
        center: [116.397428, 39.9092]
    });

    //绑定地图移动事件
    map.on('moveend', getCity);

    //获取当前城市
    function getCity() {
        map.getCity(function (data) {
            if (data['citycode'] && typeof data['citycode'] === 'string') {
                document.getElementById('city').innerHTML = (data['city'] || data['province']);
                temp = data['citycode'];
            }
        });
    }

    //绑定提交按钮
    function btnClick() {
        //数据验证，以防非法数据
        if (parseInt(document.getElementById('minprice').value) >= 0 && parseInt(document.getElementById('minprice').value) < parseInt(document.getElementById('maxprice').value)) {
            cityCode = temp;
            var pages = getTotalPages();
            var index = 1;
            houseSerach(index, pages);
        }
        else {
            alert("数据输入有误，请重新输入！");
        }
    }

    //获取总页数
    function getTotalPages() {
        var pagenum;
        $.ajax({
            type: "POST",
            url: "GetTotalPages",
            data: {
                cityCode: cityCode,
                minPrice: document.getElementById('minprice').value,
                maxPrice: document.getElementById('maxprice').value,
                area: document.getElementById("area").value,
                subway: document.getElementById("subway").value
            },
            success: function (data) {
                pagenum = data;
            }
        });
        return pagenum;
    }

    //循环获取房租信息
    function houseSerach(index, pages) {
        if (index > pages) {
            return;
        }
        $.ajax({
            type: "POST",
            url: "HouseSearch",
            data: {
                cityCode: cityCode,
                minPrice: document.getElementById('minprice').value,
                maxPrice: document.getElementById('maxprice').value,
                page: index,
                area: document.getElementById("area").value,
                subway: document.getElementById("subway").value
            },
            success: function (data) {
                index = index + 5;
                houseSerach(index, pages);
                for (var key in data) {
                    addMarker(data[key]);
                }
            }
        });
    }

    //添加坐标标记
    function addMarker(info) {
        var newGeocoder = new AMap.Geocoder({
            city: cityCode,
            radius: 1000 //范围，默认：500
        }).getLocation(info.houseLocation, function (status, result) {
            if (status === 'complete' && result.info === 'OK') {
                var geocode = result.geocodes[0];
                marker = new AMap.Marker({
                    icon: "http://webapi.amap.com/theme/v1.3/markers/n/mark_b.png",
                    position: [geocode.location.getLng(), geocode.location.getLat()]
                });
                marker.content = "<div><a target = '_blank' href='" + info.houseURL + "'>房源：" + info.houseTitle + "  租金：" + info.money + "</a><div>"
                marker.setMap(map);
                marker.on('click', markClick);
            }
        });
    }

    //绑定弹出信息事件
    function markClick(e) {
        var infoWindow = new AMap.InfoWindow({offset: new AMap.Pixel(0, -30)});
        infoWindow.setContent(e.target.content);
        infoWindow.open(map, e.target.getPosition());
    }

</script>
</html>
