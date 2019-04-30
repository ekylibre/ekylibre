[1mdiff --git a/app/assets/javascripts/backend/purchase_invoices.js.coffee b/app/assets/javascripts/backend/purchase_invoices.js.coffee[m
[1mindex e35c4ceeb2..700c62a9c0 100644[m
[1m--- a/app/assets/javascripts/backend/purchase_invoices.js.coffee[m
[1m+++ b/app/assets/javascripts/backend/purchase_invoices.js.coffee[m
[36m@@ -38,7 +38,7 @@[m
 [m
 [m
     $(document).on 'selector:change', '.invoice-variant.selector-search', (event) ->[m
[31m-      E.PurchaseInvoices.fillStocksCounters(event)[m
[32m+[m[32m      E.Purchases.fillStocksCounters(event)[m
 [m
       targettedElement = $(event.target)[m
       fieldAssetFields = targettedElement.closest('.merchandise').find('.fixed-asset-fields')[m
[36m@@ -61,10 +61,10 @@[m
 [m
 [m
     $(document).on 'change', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->[m
[31m-      E.PurchaseInvoices.fillStocksCounters(event)[m
[32m+[m[32m      E.Purchases.fillStocksCounters(event)[m
 [m
     $(document).on 'keyup', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->[m
[31m-      E.PurchaseInvoices.fillStocksCounters(event)[m
[32m+[m[32m      E.Purchases.fillStocksCounters(event)[m
 [m
     $(document).on 'click', '.nested-fields .edit-item[data-edit="item-form"]', (event) ->[m
       vatSelectedValue = $(event.target).closest('.nested-fields').find('.item-display .vat-rate').attr('data-selected-value')[m
[36m@@ -162,31 +162,6 @@[m
           else[m
             stoppedOnFieldBlock.css('display', 'block')[m
 [m
[31m-[m
[31m-    fillStocksCounters: (event) ->[m
[31m-      currentForm = $(event.target).closest('.nested-item-form')[m
[31m-      variantId = $(currentForm).find('.purchase_invoice_items_variant .selector-value').val()[m
[31m-[m
[31m-      if variantId == ""[m
[31m-        return[m
[31m-[m
[31m-      $.ajax[m
[31m-        url: "/backend/product_nature_variants/#{variantId}/detail",[m
[31m-        success: (data, status, request) ->[m
[31m-          $(currentForm).find('.merchandise-current-stock .stock-value').text(data.stock)[m
[31m-          $(currentForm).find('.merchandise-current-stock .stock-unit').text(data.unit.name)[m
[31m-[m
[31m-          quantity = 0[m
[31m-          quantityElement = $(currentForm).find('.purchase_invoice_items_quantity .invoice-quantity')[m
[31m-[m
[31m-          if ($(quantityElement).val() != "")[m
[31m-            quantity = $(quantityElement).val()[m
[31m-[m
[31m-          newStock = parseFloat(data.stock) - parseFloat(quantity)[m
[31m-          $(currentForm).find('.merchandise-stock-after-invoice .stock-value').text(newStock)[m
[31m-          $(currentForm).find('.merchandise-stock-after-invoice .stock-unit').text(data.unit.name)[m
[31m-[m
[31m-[m
   E.PurchaseInvoicesShow =[m
     addStyleToReconcilationStateBlock: ->[m
       reconcilationStateBlock = $('.change-reconcilation-state-block')[m
[1mdiff --git a/app/assets/javascripts/backend/purchase_orders.js.coffee b/app/assets/javascripts/backend/purchase_orders.js.coffee[m
[1mindex d00a51f9b7..38d3143d2f 100644[m
[1m--- a/app/assets/javascripts/backend/purchase_orders.js.coffee[m
[1m+++ b/app/assets/javascripts/backend/purchase_orders.js.coffee[m
[36m@@ -25,13 +25,13 @@[m
       $('.order-totals .order-total .total-value').text(totalAmountIncludingTaxes)[m
 [m
     $(document).on 'selector:change', '.order-variant.selector-search', (event) ->[m
[31m-      E.PurchaseOrders.fillStocksCounters(event)[m
[32m+[m[32m      E.Purchases.fillStocksCounters(event)[m
 [m
     $(document).on 'change', '.nested-fields .form-field .purchase_order_items_quantity .order-quantity', (event) ->[m
[31m-      E.PurchaseOrders.fillStocksCounters(event)[m
[32m+[m[32m      E.Purchases.fillStocksCounters(event)[m
 [m
     $(document).on 'keyup', '.nested-fields .form-field .purchase_order_items_quantity .order-quantity', (event) ->[m
[31m-      E.PurchaseOrders.fillStocksCounters(event)[m
[32m+[m[32m      E.Purchases.fillStocksCounters(event)[m
 [m
     $(document).on 'click', '.nested-fields .edit-item[data-edit="item-form"]', (event) ->[m
       vatSelectedValue = $(event.target).closest('.nested-fields').find('.item-display .vat-rate').attr('data-selected-value')[m
[36m@@ -44,28 +44,4 @@[m
         success: (data,status, request) ->[m
           $(document).find('#purchase_invoice_payment_delay').val(data.supplier_payment_delay)[m
 [m
[31m-[m
[31m-  E.PurchaseOrders =[m
[31m-    fillStocksCounters: (event) ->[m
[31m-      currentForm = $(event.target).closest('.nested-item-form')[m
[31m-      variantId = $(currentForm).find('.purchase_order_items_variant .selector-value').val()[m
[31m-[m
[31m-      if variantId == ""[m
[31m-        return[m
[31m-      $.ajax[m
[31m-        url: "/backend/product_nature_variants/#{variantId}/detail",[m
[31m-        success: (data, status, request) ->[m
[31m-          $(currentForm).find('.merchandise-current-stock .stock-value').text(data.stock)[m
[31m-          $(currentForm).find('.merchandise-current-stock .stock-unit').text(data.unit.name)[m
[31m-[m
[31m-          quantity = 0[m
[31m-          quantityElement = $(currentForm).find('.purchase_order_items_quantity .order-quantity')[m
[31m-[m
[31m-          if ($(quantityElement).val() != "")[m
[31m-            quantity = $(quantityElement).val()[m
[31m-[m
[31m-          newStock = parseFloat(data.stock) + parseFloat(quantity)[m
[31m-          $(currentForm).find('.merchandise-stock-after-order .stock-value').text(newStock)[m
[31m-          $(currentForm).find('.merchandise-stock-after-order .stock-unit').text(data.unit.name)[m
[31m-[m
 ) ekylibre, jQuery[m
[1mdiff --git a/app/assets/javascripts/backend/purchase_process/forms.js.coffee b/app/assets/javascripts/backend/purchase_process/forms.js.coffee[m
[1mindex 11154d7b20..277b6981f6 100644[m
[1m--- a/app/assets/javascripts/backend/purchase_process/forms.js.coffee[m
[1m+++ b/app/assets/javascripts/backend/purchase_process/forms.js.coffee[m
[36m@@ -16,7 +16,7 @@[m
 [m
   $(document).on "keyup change", "*[data-trade-component]", (event) ->[m
     component = $(this)[m
[31m-    item = component.closest(".storing-fields")[m
[32m+[m[32m    item = component.closest('.storing__fields')[m
     component_name = component.data('trade-component')[m
     if component_name == 'conditionning' || component_name == 'conditionning_quantity' && item.length > 0[m
       conditionning = item.find('.conditionning')[m
[1mdiff --git a/app/themes/tekyla/stylesheets/purchase_orders.scss b/app/themes/tekyla/stylesheets/purchase_orders.scss[m
[1mindex 22afa22744..374567e484 100644[m
[1m--- a/app/themes/tekyla/stylesheets/purchase_orders.scss[m
[1m+++ b/app/themes/tekyla/stylesheets/purchase_orders.scss[m
[36m@@ -122,7 +122,7 @@[m
       border-bottom: solid 1px #ddd;[m
 [m
       .merchandise-current-stock,[m
[31m-      .merchandise-stock-after-order {[m
[32m+[m[32m      .merchandise-stock-after-purchase {[m
         @include flex-row(flex-start);[m
         width: 100%;[m
       }[m
[1mdiff --git a/app/themes/tekyla/stylesheets/receptions.scss b/app/themes/tekyla/stylesheets/receptions.scss[m
[1mindex aa7aa9e54b..fb37b7ee90 100644[m
[1m--- a/app/themes/tekyla/stylesheets/receptions.scss[m
[1m+++ b/app/themes/tekyla/stylesheets/receptions.scss[m
[36m@@ -9,6 +9,8 @@[m
   font-weight: bold;[m
   font-size: $fs-small;[m
   color: white;[m
[32m+[m[32m  vertical-align: middle;[m
[32m+[m[32m  line-height: 39px;[m
 }[m
 [m
 .global-incident-warning {[m
[36m@@ -49,12 +51,16 @@[m
     display: flex;[m
     .control-label {[m
       max-width: 100% !important;[m
[31m-      margin: 0 !important;[m
[32m+[m[32m      margin: 1 !important;[m
     }[m
     .controls  {[m
       margin-left: 0 !important;[m
       max-width: 20% !important;[m
     }[m
[32m+[m[32m    .control-group {[m
[32m+[m[32m      display: flex;[m
[32m+[m[32m      align-items: center;[m
[32m+[m[32m    }[m
   }[m
 [m
   .item-form__button {[m
[36m@@ -78,7 +84,7 @@[m
 [m
   .role-row--merchandise {[m
     display: flex;[m
[31m-[m
[32m+[m[32m    min-height: 110px;[m
     .control-group {[m
       display: flex;[m
       flex-direction: row;[m
[36m@@ -123,15 +129,22 @@[m
     .control-group {[m
     display: flex;[m
     flex-direction: column;[m
[31m-    .selector {[m
[31m-      width: 70%;[m
[31m-    }[m
[32m+[m[32m      .selector {[m
[32m+[m[32m        width: 70%;[m
[32m+[m[32m      }[m
     }[m
   }[m
[32m+[m
[32m+[m[32m  .unitary-variant-fields {[m
[32m+[m[32m    display: flex;[m
[32m+[m
[32m+[m[32m  }[m
[32m+[m
   .item-block__delivery-mode {[m
     display: flex;[m
     flex-direction: column;[m
     justify-content: space-around;[m
[32m+[m[32m    max-height: 63px;[m
     .control-group {[m
     display: flex;[m
     flex-direction: column;[m
[36m@@ -167,6 +180,12 @@[m
     }[m
   }[m
 [m
[32m+[m[32m  .nested-remove{[m
[32m+[m[32m    right: 0 !important;[m
[32m+[m[32m    top: 0 !important;[m
[32m+[m[32m    position: unset !important;[m
[32m+[m[32m  }[m
[32m+[m
   .storing__footer {[m
     display: flex;[m
     align-items: center;[m
[1mdiff --git a/app/views/backend/purchase_orders/_item_fields.html.haml b/app/views/backend/purchase_orders/_item_fields.html.haml[m
[1mindex 8abc87918c..f365ca2c64 100644[m
[1m--- a/app/views/backend/purchase_orders/_item_fields.html.haml[m
[1m+++ b/app/views/backend/purchase_orders/_item_fields.html.haml[m
[36m@@ -86,7 +86,7 @@[m
         %span.stock-label= :current_stock.tl[m
         %span.stock-value= f.object.decorate.merchandise_current_stock[m
         %span.stock-unit= f.object.decorate.merchandise_stock_unit[m
[31m-      .merchandise-stock-after-order[m
[32m+[m[32m      .merchandise-stock-after-purchase[m
         %span.stock-label= :stock_after_order.tl[m
         %span.stock-value= f.object.decorate.merchandise_stock_after_order[m
         %span.stock-unit= f.object.decorate.merchandise_stock_unit[m
[1mdiff --git a/app/views/backend/receptions/_item_fields.html.haml b/app/views/backend/receptions/_item_fields.html.haml[m
[1mindex 6c70bf38dc..92d117efb4 100644[m
[1m--- a/app/views/backend/receptions/_item_fields.html.haml[m
[1m+++ b/app/views/backend/receptions/_item_fields.html.haml[m
[36m@@ -44,11 +44,11 @@[m
           = render 'non_merchandise_fields', f: f, variant: variant, non_compliant_message: non_compliant_message[m
 [m
       .item-form__information[m
[31m-        .item-form__project-budget[m
[32m+[m[32m        .item-form__activity[m
           = f.referenced_association :project_budget[m
         .item-form__project-budget[m
           = f.referenced_association :project_budget[m
[31m-        .item-form__equipment[m
[32m+[m[32m        .item-form__product_work_number[m
           = f.referenced_association :equipment, source: :tools, label: :equipment.tl, input_html: {data: { remember: 'equipment'}}[m
         .item-form__equipment[m
           = f.referenced_association :equipment, source: :tools, label: :equipment.tl, input_html: {data: { remember: 'equipment'}}[m
[1mdiff --git a/app/views/backend/receptions/_merchandise_fields.haml b/app/views/backend/receptions/_merchandise_fields.haml[m
[1mindex 99981ecde9..7b13258c2c 100644[m
[1m--- a/app/views/backend/receptions/_merchandise_fields.haml[m
[1m+++ b/app/views/backend/receptions/_merchandise_fields.haml[m
[36m@@ -5,11 +5,11 @@[m
 [m
       - display = ""[m
       - display = "display: none;" unless variant.identifiable?.or_else(false)[m
[31m-      .unitary-variant-fields{style: display, data: {"when-item": "identifiable", "when-display-value": 'true', "when-scope": 'unit'}}[m
[31m-        = f.input :name, wrapper: :nested_append do[m
[31m-          = f.input_field :product_name, placeholder: ParcelItem.human_attribute_name(:product_name)[m
[31m-        = f.input :work_number, wrapper: :nested_append do[m
[31m-          = f.input_field :product_work_number, placeholder: ParcelItem.human_attribute_name(:product_work_number)[m
[32m+[m[32m    .unitary-variant-fields{style: display, data: {"when-item": "identifiable", "when-display-value": 'true', "when-scope": 'unit'}}[m
[32m+[m[32m      = f.input :name, wrapper: :nested_append do[m
[32m+[m[32m        = f.input_field :product_name, placeholder: ParcelItem.human_attribute_name(:product_name)[m
[32m+[m[32m      = f.input :work_number, wrapper: :nested_append do[m
[32m+[m[32m        = f.input_field :product_work_number, placeholder: ParcelItem.human_attribute_name(:product_work_number)[m
 [m
   .item-block__delivery-mode{style: "display: flex"}[m
     = f.label :delivery_mode.tl[m
[36m@@ -28,7 +28,7 @@[m
       = f.simple_fields_for :storings, f.object.storings do |storing|[m
         = render 'storing_fields', f: storing[m
     .div.storing__footer[m
[31m-      = link_to_add_association :add_storing.tl, f, :storings, partial: 'storing_fields', class: "link-add-storing", data: { :'association-insertion-traversal' => :closest, :'association-insertion-node' => '.storings-footer', :'association-insertion-method' => :before }[m
[32m+[m[32m      = link_to_add_association :add_storing.tl, f, :storings, partial: 'storing_fields', class: "link-add-storing", data: { :'association-insertion-traversal' => :closest, :'association-insertion-node' => '.storing__footer', :'association-insertion-method' => :before }[m
       %label.total-labels[m
         %span.total= :total.tl[m
         %span.total-quantity{ data: { calculate: "sum", use: ".storing-fields:not(.removed-nested-fields) .storing-quantity", use_closest: ".nested-item-form", calculate_round: 2 } }= 0.0[m
[1mdiff --git a/app/views/backend/receptions/_storing_fields.html.haml b/app/views/backend/receptions/_storing_fields.html.haml[m
[1mindex c98607df73..58e75a9d8b 100644[m
[1m--- a/app/views/backend/receptions/_storing_fields.html.haml[m
[1m+++ b/app/views/backend/receptions/_storing_fields.html.haml[m
[36m@@ -2,11 +2,12 @@[m
 - variant = Maybe(storing.parcel_item.variant)[m
 - storage_name = storing.storage.name if storing.storage[m
 [m
[31m-.storing__fields[m
[32m+[m[32m.nested-fields.storing__fields[m
   %input.hidden{data: { 'when-item': 'name', 'when-set-value': 'RECORD_VALUE', 'when-scope': 'storage'}, value: storage_name}[m
   .nested-remove.act[m
     - if f.object.destroyable?[m
       = link_to_remove_association(content_tag(:i) + h(:destroy.tl), f, 'data-no-turbolink' => true, class: 'destroy remove remove-item')[m
[32m+[m
   = f.input :conditionning, wrapper: :conditionning_append do[m
     = f.input_field :conditionning , class: "conditionning", data: { trade_component: 'conditionning' }[m
     %span.add-on.storage-unit-name{data: { 'when-item': 'unit_name', 'when-set-value': 'RECORD_VALUE', 'when-scope': 'unit'}}[m
