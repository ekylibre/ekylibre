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
        unwrap = ko.utils.unwrapObservable,
        dataGet = ko.utils.domData.get,
        dataSet = ko.utils.domData.set,
        version = $.ui && $.ui.version,
        //1.8.24 included a fix for how events were triggered in nested sortables. indexOf checks will fail if version starts with that value (0 vs. -1)
        hasNestedSortableFix = version && version.indexOf("1.6.") && version.indexOf("1.7.") && (version.indexOf("1.8.") || version === "1.8.24");

    //internal afterRender that adds meta-data to children
    var addMetaDataAfterRender = function(elements, data) {
        ko.utils.arrayForEach(elements, function(element) {
            if (element.nodeType === 1) {
                if($(element).hasClass('animal-container'))
                {
                    //console.log(element,CONTAINERKEY,data);
                    dataSet(element, CONTAINERKEY, data);

                }

                console.log('metadata', element,data);
                dataSet(element, ITEMKEY, data);
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
                        console.log('helping');
                        var elements = [];

                        var elements = $('.checker.active').closest('.animal-element-actions').siblings('.animal-element-img').children().clone();

                        if(!elements.length)
                        {
                            console.log('item cloné !!!',item.clone());
                            elements.push(item.clone());
                        }

                        var helper = $("<div class='animate-dragging' style='width:50px;height:50px'></div>");

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

                            //img
                            //console.log(elements);
                            container.append(elements[0]);
                            container.addClass('animate-dragging-img');
                            helper.append(container);

                        }

                        return helper;

                    },
                    start: function(event, ui) {
                        //track original index
                        var el = ui.item[0];
                        dataSet(el, INDEXKEY, ko.utils.arrayIndexOf(ui.item.parent().children(), el));

                        console.log('start');
                        el = $('.checker.active').closest('.animal-element').not('.ui-sortable-placeholder');

                        console.log(el);
                        console.log('st1:',dataGet(el[0],ITEMKEY));
                        console.log('st2:',dataGet(el[1],ITEMKEY));
                        ui.item.data('items', el);

                        //$('.animal-element.selected').not(item).addClass('hidden');
                        //$(el).addClass('hidden');

                        //console.log(ui.item.data('items'));

                        //make sure that fields have a chance to update model
                        ui.item.find("input:focus").change();
                        if (startActual) {
                            startActual.apply(this, arguments);
                        }
                    },
                    receive: function(event, ui) {

                        console.log('receive');
                        //dragItem = dataGet(ui.item[0], DRAGKEY);
                        //dragItem = ui.item;
                        //console.log('receive');
                        //dragItem = ui.item.data('items');
                        //console.log('receive:', ui.item);
                        //console.log('data receive:', ui.item);


                        /*if (dragItem) {*/
                            //copy the model item, if a clone option is provided
                            /*if (dragItem.clone) {
                                console.log('clone');
                                dragItem = dragItem.clone();
                            }*/

                            //configure a handler to potentially manipulate item before drop
                           /*     console.log('dragItem');
                            if (sortable.dragged) {
                                console.log('dragged');
                                dragItem = sortable.dragged.call(this, dragItem, event, ui) || dragItem;
                            }
                            console.log("after:", dragItem);
                        }*/
                    },
                     stop: function (e, ui) {
                         console.log('stop');
                         //console.log(ui.item);
                         //ui.item.removeClass('hidden');
                         //ui.item.siblings().removeClass('hidden');
                        //ui.item.before($("<div class='alert alert-success'>Déplacement effectué</div>"));
                        //$('.selected').removeClass('selected');
                    },
                    update: function(event, ui) {
                        var sourceParent, targetParent, sourceIndex, targetIndex, arg,
                            el = ui.item[0],
                            parentEl = ui.item.parent()[0],
                            containerEl = ui.item.closest('.animal-container')[0],
                            item = dataGet(el, ITEMKEY) || dragItem;

                        if(containerEl != undefined)
                        {

                            console.log(ui.item);
                            console.log('container:',containerEl);
                            containerItem = dataGet(containerEl,CONTAINERKEY);
                            //item = dataGet( dragItem, ITEMKEY);

                            el = ui.item.data('items');
                            console.log('el:',el);
                            ko.utils.arrayForEach(el, function(item) {
                                console.log('foreach:',item);
                                observableItem = dataGet(item, ITEMKEY);

                                console.log(observableItem);
                                observableItem.container_id(containerItem.id);
                                dataSet(item, ITEMKEY, null);
                                $(item).remove();
                                console.log('afterRemove',$(item));

                                observableItem.checked(false)

                                dataSet($(item), ITEMKEY, observableItem);


                            });


                        }

                        var hay = $('.animal-element');
                        console.log(hay.length);


                        ko.utils.arrayForEach(hay, function(i) {
                            console.log('stUP:',dataGet(i,ITEMKEY));
                            //console.log('stUP2:',dataGet(el[1],ITEMKEY));
                        });

                           /* console.log('dragItem:', dragItem);
                            console.log(item);
                            console.log("parentEl:", parentEl);
                            console.log("parentobservable:", containerItem);*/
                            /*for(i = 0; i<dragItem.length; i++)
                            {
                                console.log(dataGet(dragItem[i], ITEMKEY));

                            }*/
                     /*   console.log('item',ui.item);
                        console.log('item_data:',ui.item.data('items'));
                        dragItem = null;
                        */
                        //item.container_id(containerItem.id);
                        //console.log(item.);

                        //make sure that moves only run once, as update fires on multiple containers
                        /*if (item && (this === parentEl) || (!hasNestedSortableFix && $.contains(this, parentEl))) {
                            //identify parents
                            sourceParent = dataGet(el, PARENTKEY);
                            sourceIndex = dataGet(el, INDEXKEY);
                            targetParent = dataGet(el.parentNode, LISTKEY);
                            targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el);

                            console.log('sourceParent: ', sourceParent());
                            console.log('sourceIndex: ', sourceIndex);
                            console.log('targetParent: ', targetParent());
                            console.log('targetIndex: ', targetIndex);

                            //take destroyed items into consideration
                            if (!templateOptions.includeDestroyed) {
                                sourceIndex = updateIndexFromDestroyedItems(sourceIndex, sourceParent);
                                targetIndex = updateIndexFromDestroyedItems(targetIndex, targetParent);
                            }

                            //build up args for the callbacks
                            if (sortable.beforeMove || sortable.afterMove) {
                                arg = {
                                    item: item,
                                    sourceParent: sourceParent,
                                    sourceParentNode: sourceParent && ui.sender || el.parentNode,
                                    sourceIndex: sourceIndex,
                                    targetParent: targetParent,
                                    targetIndex: targetIndex,
                                    cancelDrop: false
                                };

                                //execute the configured callback prior to actually moving items
                                if (sortable.beforeMove) {
                                    sortable.beforeMove.call(this, arg, event, ui);
                                }
                            }

                            //call cancel on the correct list, so KO can take care of DOM manipulation
                            if (sourceParent) {
                                $(sourceParent === targetParent ? this : ui.sender || this).sortable("cancel");
                            }
                            //for a draggable item just remove the element
                            else {
                                $(el).remove();
                            }

                            //if beforeMove told us to cancel, then we are done
                            if (arg && arg.cancelDrop) {
                                return;
                            }

                            //do the actual move
                            if (targetIndex >= 0) {
                                if (sourceParent) {
                                    sourceParent.splice(sourceIndex, 1);

                                    //if using deferred updates plugin, force updates
                                    if (ko.processAllDeferredBindingUpdates) {
                                        ko.processAllDeferredBindingUpdates();
                                    }
                                }

                                targetParent.splice(targetIndex, 0, item);
                            }

                            //rendering is handled by manipulating the observableArray; ignore dropped element
                            dataSet(el, ITEMKEY, null);

                            //if using deferred updates plugin, force updates
                            if (ko.processAllDeferredBindingUpdates) {
                                ko.processAllDeferredBindingUpdates();
                            }

                            //allow binding to accept a function to execute after moving the item
                            if (sortable.afterMove) {
                                sortable.afterMove.call(this, arg, event, ui);
                            }
                        }*/

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

            console.log('update ko');
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
            console.log("draggable:",element);
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
