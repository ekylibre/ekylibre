// knockout-sortable 0.10.0 | (c) 2015 Ryan Niemeyer |  http://www.opensource.org/licenses/mit-license
;(function(factory) {
    if (typeof define === "function" && define.amd) {
        // AMD anonymous module
        define(["knockout", "jquery", "jquery.ui/sortable"], factory);
    } else if (typeof require === "function" && typeof exports === "object" && typeof module === "object") {
        // CommonJS module
        var ko = require("knockout"),
            jQuery = require("jquery");
        require("jquery.ui/sortable");
        factory(ko, jQuery);
    } else {
        // No module loader (plain <script> tag) - put directly in global namespace
        factory(window.ko, window.jQuery);
    }
})(function(ko, $) {
    var ITEMKEY = "ko_sortItem",
        INDEXKEY = "ko_sourceIndex",
        LISTKEY = "ko_sortList",
        PARENTKEY = "ko_parentList",
        DRAGKEY = "ko_dragItem",
        CONTAINERKEY = "ko_containerItem",
        GROUPKEY = "ko_groupItem",
        unwrap = ko.utils.unwrapObservable,
        dataGet = ko.utils.domData.get,
        dataSet = ko.utils.domData.set,
        version = $.ui && $.ui.version,
        //1.8.24 included a fix for how events were triggered in nested sortables. indexOf checks will fail if version starts with that value (0 vs. -1)
        hasNestedSortableFix = version && version.indexOf("1.6.") && version.indexOf("1.7.") && (version.indexOf("1.8.") || version === "1.8.24");

    var addMetaDataAfterRender = function(elements, data) {
        //internal afterRender that adds meta-data to children
        ko.utils.arrayForEach(elements, function(element) {
            if (element.nodeType === 1) {
                if($(element).hasClass('animal-container'))
                {

                    dataSet(element, CONTAINERKEY, data);
                }
                else if($(element).hasClass('animal-group'))
                {

                    dataSet(element, GROUPKEY, data);
                }
                else if($(element).hasClass('animal-element'))
                {
                    dataSet(element, ITEMKEY, data);
                }
                dataSet(element, PARENTKEY, dataGet(element.parentNode, LISTKEY));

            }
        });
    };

    //prepare the proper options for the template binding
    var prepareTemplateOptions = function(valueAccessor, dataName) {
        var result = {},
            options = unwrap(valueAccessor()) || {},
            actualAfterRender;

        //build our options to pass to the template engine
        if (options.data) {
            result[dataName] = options.data;
            result.name = options.template;
        } else {
            result[dataName] = valueAccessor();
        }

        ko.utils.arrayForEach(["afterAdd", "afterRender", "as", "beforeRemove", "includeDestroyed", "templateEngine", "templateOptions", "nodes"], function (option) {
            if (options.hasOwnProperty(option)) {
                result[option] = options[option];
            } else if (ko.bindingHandlers.sortable.hasOwnProperty(option)) {
                result[option] = ko.bindingHandlers.sortable[option];
            }
        });

        //use an afterRender function to add meta-data
        if (dataName === "foreach") {
            if (result.afterRender) {
                //wrap the existing function, if it was passed
                actualAfterRender = result.afterRender;
                result.afterRender = function(element, data) {
                    addMetaDataAfterRender.call(data, element, data);
                    actualAfterRender.call(data, element, data);
                };
            } else {
                result.afterRender = addMetaDataAfterRender;
            }
        }

        //return options to pass to the template binding
        return result;
    };

    var updateIndexFromDestroyedItems = function(index, items) {
        var unwrapped = unwrap(items);

        if (unwrapped) {
            for (var i = 0; i < index; i++) {
                //add one for every destroyed item we find before the targetIndex in the target array
                if (unwrapped[i] && unwrap(unwrapped[i]._destroy)) {
                    index++;
                }
            }
        }

        return index;
    };

    //remove problematic leading/trailing whitespace from templates
    var stripTemplateWhitespace = function(element, name) {
        var templateSource,
            templateElement;

        //process named templates
        if (name) {
            templateElement = document.getElementById(name);
            if (templateElement) {
                templateSource = new ko.templateSources.domElement(templateElement);
                templateSource.text($.trim(templateSource.text()));
            }
        }
        else {
            //remove leading/trailing non-elements from anonymous templates
            $(element).contents().each(function() {
                if (this && this.nodeType !== 1) {
                    element.removeChild(this);
                }
            });
        }
    };

    //connect items with observableArrays
    ko.bindingHandlers.sortable = {
        init: function(element, valueAccessor, allBindingsAccessor, data, context) {
            var $element = $(element),
                value = unwrap(valueAccessor()) || {},
                templateOptions = prepareTemplateOptions(valueAccessor, "foreach"),
                sortable = {},
                startActual, updateActual;

            stripTemplateWhitespace(element, templateOptions.name);

            //build a new object that has the global options with overrides from the binding
            $.extend(true, sortable, ko.bindingHandlers.sortable);
            if (value.options && sortable.options) {
                ko.utils.extend(sortable.options, value.options);
                delete value.options;
            }
            ko.utils.extend(sortable, value);

            //if allowDrop is an observable or a function, then execute it in a computed observable
            if (sortable.connectClass && (ko.isObservable(sortable.allowDrop) || typeof sortable.allowDrop == "function")) {
                ko.computed({
                    read: function() {
                        var value = unwrap(sortable.allowDrop),
                            shouldAdd = typeof value == "function" ? value.call(this, templateOptions.foreach) : value;
                        ko.utils.toggleDomNodeCssClass(element, sortable.connectClass, shouldAdd);
                    },
                    disposeWhenNodeIsRemoved: element
                }, this);
            } else {
                ko.utils.toggleDomNodeCssClass(element, sortable.connectClass, sortable.allowDrop);
            }

            //wrap the template binding
            ko.bindingHandlers.template.init(element, function() { return templateOptions; }, allBindingsAccessor, data, context);

            //keep a reference to start/update functions that might have been passed in
            startActual = sortable.options.start;
            updateActual = sortable.options.update;

            //initialize sortable binding after template binding has rendered in update function
            var createTimeout = setTimeout(function() {
                var dragItem;
                $element.sortable(ko.utils.extend(sortable.options, {
                    helper: function (e, item) {
                        var elements = [];
                        var helper;

                        if((dataGet(item[0],GROUPKEY) != undefined) || dataGet(item[0],CONTAINERKEY) != undefined)
                        {
                            //TODO: cause dragging issue
                            //helper = $(item[0]).addClass('group-dragging');
                            helper = $(item[0]);
                        }
                        else if (dataGet(item[0],ITEMKEY) != undefined)
                        {

                            elements = $('.checker.active').closest('.animal-element-actions').siblings('.animal-element-img').children().clone();

                            if(!elements.length)
                            {
                                elements.push(item.clone());
                            }

                            helper = $("<div class='animate-dragging' style='width:50px;height:50px'></div>");

                            if(elements.length > 1)
                            {
                                helper.append($("<div class='animate-dragging-number'>"+elements.length+"</div>"));
                                var z = 0;
                                for(var i=0;i < elements.length; i++)
                                {
                                    t = -i * 5;
                                    var container = $("<div/>");
                                    $(elements[i]).css('top',t+'px');
                                    $(elements[i]).css('left',-t+'px');
                                    $(elements[i]).css('z-index',z);
                                    container.append(elements[i]);
                                    container.addClass('animate-dragging-img');
                                    helper.append(container);
                                    z = z - 1;
                                }

                            }
                            else{
                                var container = $("<div/>");

                                container.append(elements[0]);
                                container.addClass('animate-dragging-img');
                                helper.append(container);

                            }
                        }


                        return helper;

                    },
                    start: function(event, ui) {
                        //track original index
                        var el = ui.item[0];


                        //Moving an animal
                        if(dataGet(el,ITEMKEY) != undefined)
                        {


                            el = $('.checker.active').closest('.animal-element').not('.ui-sortable-placeholder');

                            ui.item.data('items', el);

                            $('.animal-container .body .animal-dropzone').addClass('grow-empty-zone');
                        }

                        if((dataGet(el,GROUPKEY) != undefined) || (dataGet(el,CONTAINERKEY) != undefined))
                        {
                            //Need to set current array position
                            dataSet(el, INDEXKEY, ko.utils.arrayIndexOf(ui.item.parent().children(), el));

                        }


                        //make sure that fields have a chance to update model
                        ui.item.find("input:focus").change();
                        if (startActual) {
                            startActual.apply(this, arguments);
                        }
                    },
                    receive: function(event, ui) {

                        var el = ui.item[0];


                        if(dataGet(el, ITEMKEY) != undefined)
                        {
                            var containerEl = ui.item.closest('.animal-container')[0];
                            var animals = [];
                            var containerItem;

                            if(containerEl != undefined)
                            {

                                containerItem = dataGet(containerEl,CONTAINERKEY);

                                el = ui.item.data('items');
                                ko.utils.arrayForEach(el, function(item) {

                                    if((observableItem = dataGet(item, ITEMKEY)) != null)
                                    {

                                        animals.push(observableItem);
                                        $(item).remove();

                                    }



                                });
                            }

                            window.app.toggleMoveAnimalModal(animals,containerItem);

                        }

                    },
                     stop: function (e, ui) {

                         var el = ui.item[0];

                         $('.animal-container .body .animal-dropzone').removeClass('grow-empty-zone');

                         if(dataGet(el,GROUPKEY) != undefined)
                         {
                             //$(el).removeClass('group-dragging');
                         }

                     },
                    update: function(event, ui) {

                        var el = ui.item[0];


                        if((observableItem = dataGet(el,GROUPKEY)) != undefined)
                        {
                            sourceParent = dataGet(el, PARENTKEY);
                            sourceIndex = dataGet(el, INDEXKEY);
                            targetParent = dataGet(el.parentNode, LISTKEY);
                            targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el);


                            //do the actual move
                            if (targetIndex >= 0) {
                                if (sourceParent) {
                                    sourceParent.splice(sourceIndex, 1);

                                }

                                targetParent.splice(targetIndex, 0, observableItem);
                            }

                            //update preferences
                            window.app.updatePreferences();

                        }

                        console.log('el',el);

                        if (dataGet(el,CONTAINERKEY) != undefined)
                        {
                            //var groupEl = ui.item.closest('.animal-group')[0];
                            //var groupItem;

                            //if(groupEl != undefined)
                            //{

                            //groupItem = dataGet(groupEl,GROUPKEY);

                            //el = ui.item.data('items');
                            //ko.utils.arrayForEach(el, function(item) {
                            //
                            //    if((observableItem = dataGet(item, ITEMKEY)) != null)
                            //    {
                            //
                            //        animals.push(observableItem);
                            //        $(item).remove();
                            //
                            //    }
                            //
                            //
                            //
                            //});
                            //sourceParent = dataGet(el, PARENTKEY);
                            //sourceParent2 = dataGet(el, GROUPKEY);
                            //sourceIndex = dataGet(el, INDEXKEY);
                            targetParent = dataGet(el.parentNode, LISTKEY);
                            targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el);
                            var observableItem;
                            //
                            //console.log('sp', sourceParent());
                            //console.log('sp2', sourceParent2());
                            //console.log('si', sourceIndex);
                            console.log('tp', targetParent());
                            console.log('ti', targetIndex);

                            ko.utils.arrayForEach(ui.item.parent().children(), function(item) {
                                console.log('item',item);
                                if((observableItem = dataGet(item, CONTAINERKEY)) != null)
                                    {
                                        console.log('obsItem',observableItem);
                                //
                                //        animals.push(observableItem);
                                //        $(item).remove();
                                //
                                    }
                            });

                        //}

                        }


                        if (updateActual) {
                            updateActual.apply(this, arguments);
                        }
                    },
                    connectWith: sortable.connectClass ? "." + sortable.connectClass : false
                }));

                //handle enabling/disabling sorting
                if (sortable.isEnabled !== undefined) {
                    ko.computed({
                        read: function() {
                            $element.sortable(unwrap(sortable.isEnabled) ? "enable" : "disable");
                        },
                        disposeWhenNodeIsRemoved: element
                    });
                }
            }, 0);

            //handle disposal
            ko.utils.domNodeDisposal.addDisposeCallback(element, function() {
                //only call destroy if sortable has been created
                if ($element.data("ui-sortable") || $element.data("sortable")) {
                    $element.sortable("destroy");
                }

                ko.utils.toggleDomNodeCssClass(element, sortable.connectClass, false);

                //do not create the sortable if the element has been removed from DOM
                clearTimeout(createTimeout);
            });

            return { 'controlsDescendantBindings': true };
        },
        update: function(element, valueAccessor, allBindingsAccessor, data, context) {
            var templateOptions = prepareTemplateOptions(valueAccessor, "foreach");

            //attach meta-data
            dataSet(element, LISTKEY, templateOptions.foreach);

            //call template binding's update with correct options
            ko.bindingHandlers.template.update(element, function() { return templateOptions; }, allBindingsAccessor, data, context);
        },
        connectClass: 'ko_container',
        allowDrop: true,
        afterMove: null,
        beforeMove: null,
        options: {}
    };

    //create a draggable that is appropriate for dropping into a sortable
    ko.bindingHandlers.draggable = {
        init: function(element, valueAccessor, allBindingsAccessor, data, context) {
            var value = unwrap(valueAccessor()) || {},
                options = value.options || {},
                draggableOptions = ko.utils.extend({}, ko.bindingHandlers.draggable.options),
                templateOptions = prepareTemplateOptions(valueAccessor, "data"),
                connectClass = value.connectClass || ko.bindingHandlers.draggable.connectClass,
                isEnabled = value.isEnabled !== undefined ? value.isEnabled : ko.bindingHandlers.draggable.isEnabled;

            value = "data" in value ? value.data : value;

            //set meta-data
            dataSet(element, DRAGKEY, value);

            //override global options with override options passed in
            ko.utils.extend(draggableOptions, options);

            //setup connection to a sortable
            draggableOptions.connectToSortable = connectClass ? "." + connectClass : false;

            //initialize draggable
            $(element).draggable(draggableOptions);

            //handle enabling/disabling sorting
            if (isEnabled !== undefined) {
                ko.computed({
                    read: function() {
                        $(element).draggable(unwrap(isEnabled) ? "enable" : "disable");
                    },
                    disposeWhenNodeIsRemoved: element
                });
            }

            //handle disposal
            ko.utils.domNodeDisposal.addDisposeCallback(element, function() {
                $(element).draggable("destroy");
            });

            return ko.bindingHandlers.template.init(element, function() { return templateOptions; }, allBindingsAccessor, data, context);
        },
        update: function(element, valueAccessor, allBindingsAccessor, data, context) {
            var templateOptions = prepareTemplateOptions(valueAccessor, "data");

            return ko.bindingHandlers.template.update(element, function() { return templateOptions; }, allBindingsAccessor, data, context);
        },
        connectClass: ko.bindingHandlers.sortable.connectClass,
        options: {
            helper: "clone"
        }
    };
});
