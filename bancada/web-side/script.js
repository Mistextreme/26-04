function openNui(data) {
  if (data.drugs) {
    let drugsContainer = "";

    data.drugs.forEach((drug, index) => {
      drugsContainer += `
        <div class="item" data-key="${index+1}">
          <h3>${drug.name}</h3>
          <div class="container-img"><img src="${drug.image}"></div>
          <ul class="infos-item">
            <li>qtd atual: <span class="drugCount">${drug.counnInTable}</span></li>
            <li>qtd no inv: <span>${drug.invQtd}</span></li>
            <li>boost: <span>desativado</span></li>
          </ul>
          <button class="select-button" data-key="${index+1}">selecionar</button>
        </div>`;
    });
    $(".container-itens").html(drugsContainer);
    assignButtonClickHandlers();
  }
  $("#root").css("display", "block");
  $("#root").animate({
    left: "40px"
  }, 500);
}

function attCountInTable(data) {
  let element = $(`.item[data-key="${data.drug}"]`)
  element.find(".drugCount").text(data.drugcount)
}

function assignButtonClickHandlers() {
  $('.select-button').click(function() {
    $('.select-button').removeClass('active');
    $(this).addClass('active');
  });
}

function closeNUI() {
  $.post(`http://bancada/closeNui`, JSON.stringify({}));
  $("#root").animate({
    left: "-360px"
  }, 500, function() {
    $("#root").css("display", "none");
  });
}

function startSale() {
  $.post(`http://bancada/startSale`, JSON.stringify({}), function() {
    $("#root").animate({
      left: "-360px"
    }, 500, function() {
      $("#root").css("display", "none");
    });
  });
}

$(document).ready(function() {
  $('#add').click(function() {
    var activeButton = $('.select-button.active');
    if (activeButton.length > 0) {
      var dataKey = activeButton.data('key');
      $.post(`http://bancada/addDrug`, JSON.stringify({ dataKey }));
    }
  });

  $('#remove').click(function() {
    var activeButton = $('.select-button.active');
    if (activeButton.length > 0) {
      var dataKey = activeButton.data('key');
      $.post(`http://bancada/removeDrug`, JSON.stringify({ dataKey }));
    }
  });

  $('#startSale').click(function() {
    closeNUI();
    startSale();
  });

  window.addEventListener("message", ({ data }) => {
    if (data.action) {
      window[data.action](data);
    }
  });

  window.addEventListener("keydown", ({ key }) => {
    if (key === "Escape") {
      closeNUI();
    }
  });
});