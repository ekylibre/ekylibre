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
        DROPKEY = "ko_dropItem",
        CONTAINERKEY = "ko_containerItem",
        GROUPKEY = "ko_groupItem",
        PARENTGROUPKEY = "ko_parentGroupItem",
        sortableIn = 0;
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
                    dataSet(element, PARENTGROUPKEY, dataGet($(element).closest('.animal-group')[0], GROUPKEY));

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
                            elements = $('.checker.active').closest('.animal-element').find('.animal-element-infos .animal-element-name span').clone();

                            if(!elements.length)
                            {
                                elements.push(item.clone());
                            }

                            helper = $("<div class='animate-dragging' style='width: 130px; height: 30px'></div>");

                            if(elements.length > 1)
                            {
                                helper.append($("<div class='animate-dragging-number'>"+elements.length+"</div>"));
                                var z = 0;
                                for(var i=0;i < elements.length; i++)
                                {
                                    t = -i * 5;

                                    var container = $("<div style='width: 130px; height: 30px; color: white; vertical-align: middle; text-align: center; font-weight: bold; font-size:14px; line-height:20px; background-color: #428bca; box-shadow: 1px 1px 8px #000000;'></div>");

                                    $(container).css('top',t+'px');
                                    $(container).css('left',-t+'px');
                                    $(container).css('z-index',z);
                                    container.append($(elements[i]).text());
                                    container.addClass('animate-dragging-img');
                                    helper.append(container);
                                    z = z - 1;
                                }

                            }
                            else{
                                var container = $("<div style='width: 130px; height: 30px; vertical-align: middle; text-align: center; font-size:14px; line-height:20px'></div>");

                                container.append($(elements[0]).text());
                                container.addClass('animate-dragging-text');


                                helper.append(container);

                            }
                        }
                        else{

                            //fallback
                            helper = $("<div class='animate-dragging' style='width:50px;height:50px'></div>");

                        }

                        return helper;

                    },
                    sort: function(event, ui) {
                        //var $target = $(event.target);
                        //if (!/html|body/i.test($target.offsetParent()[0].tagName)) {
                        //    var left = event.pageX - $target.offsetParent().offset().left - (ui.helper.outerHeight(true) / 2);
                        //    ui.helper.css({'left' : left + 'px'});
                        //}
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
                            $('.add-container').css('display','block');
                            $('.add-container').addClass('grow-empty-zone');

                        }

                        if(dataGet(el,GROUPKEY) != undefined)
                        {
                            //Need to set current array position
                            dataSet(el, INDEXKEY, ko.utils.arrayIndexOf(ui.item.parent().children(), el));

                        }

                        var containerItem;
                        if((containerItem = dataGet(el,CONTAINERKEY)) != undefined)
                        {
                            dataSet(el, INDEXKEY, containerItem.position());
                        }

                        //make sure that fields have a chance to update model
                        ui.item.find("input:focus").change();
                        if (startActual) {
                            startActual.apply(this, arguments);
                        }
                    },
                    over: function (event, ui) {
                        sortableIn = 1;
                        $(".sorting-animal-placeholder").css('display','block');
                    },
                    out: function (event, ui) {
                        sortableIn = 0;
                        $(".sorting-animal-placeholder").css('display','none');
                    },
                    receive: function(event, ui) {

                        var el = ui.item[0];
                        if((dataGet(el, ITEMKEY) != undefined) && sortableIn)
                        {
                            var containerEl = ui.item.closest('.animal-container')[0];
                            var animals = [];
                            var containerItem;

                            if(containerEl != undefined)
                            {

                                containerItem = dataGet(containerEl,CONTAINERKEY);

                                var observableItem;

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

                        if(!sortableIn)
                        {
                            $(ui.sender || this).sortable("cancel");
                        }

                    },
                     stop: function (e, ui) {

                         var el = ui.item[0];

                         $('.animal-container .body .animal-dropzone').removeClass('grow-empty-zone');
                         $('.add-container').removeClass('grow-empty-zone');
                         $('.add-container').css('display','none');

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

                        if (dataGet(el,CONTAINERKEY) != undefined)
                        {

                            //sourceParent = dataGet(el, PARENTKEY);
                            var sourceParentGroup = dataGet(el, PARENTGROUPKEY);
                            var sourceIndex = dataGet(el, INDEXKEY);
                            var targetParent = dataGet(ui.item.closest('.animal-group')[0], GROUPKEY);
                            var targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el);
                            var containerItem;

                            containerItem = dataGet(el, CONTAINERKEY);
                            if(sourceParentGroup && targetParent && !isNaN(sourceIndex) && !isNaN(targetIndex))
                            {
                                window.app.moveContainer(containerItem,sourceParentGroup,sourceIndex,targetParent,targetIndex);
                            }

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

    ko.bindingHandlers.droppable = {
        init: function (element, valueAccessor, allBindingsAccessor, data, context) {
            var $element = $(element),
                value = ko.utils.unwrapObservable(valueAccessor()) || {},
                droppable = {},
                dropActual;

            $.extend(true, droppable, ko.bindingHandlers.droppable);
            if (value.data) {
                if (value.options && droppable.options) {
                    ko.utils.extend(droppable.options, value.options);
                    delete value.options;
                }
                ko.utils.extend(droppable, value);
            } else {
                droppable.data = value;
            }


            dropActual = droppable.options.drop;

            $element.droppable(ko.utils.extend(droppable.options, {
                out: function(e, ui) {
                },
                over: function( e, ui ){
                    var container;
                    if((container = dataGet($(this)[0], CONTAINERKEY)))
                    {
                        container.hidden(false);
                    }
                },
                drop: function (event, ui) {
                    var sourceParent, targetParent, targetGroup, targetIndex, i, targetUnwrapped, arg,
                        el = ui.draggable[0],
                        item = dataGet(el, ITEMKEY) || dataGet(el, DRAGKEY);


                    if(!sortableIn)
                    {
                        if (item && item.clone)
                            item = item.clone();

                        if (item) {

                            targetGroup = dataGet($(this).closest('.animal-group')[0], GROUPKEY);

                            el = ui.draggable.data('items');

                            ko.utils.arrayForEach(el, function(item) {

                                if((observableItem = dataGet(item, ITEMKEY)) != null)
                                {
                                    window.app.droppedAnimals.push(observableItem);
                                }

                            });


                            window.app.toggleNewContainerModal(targetGroup);


                            if (dropActual) {
                                dropActual.apply(this, arguments);
                            }
                        }
                    }
                }
            }));

            //handle enabling/disabling
            if (droppable.isEnabled !== undefined) {
                ko.computed({
                    read: function () {
                        $element.droppable(ko.utils.unwrapObservable(droppable.isEnabled) ? "enable" : "disable");
                    },
                    disposeWhenNodeIsRemoved: element
                });
            }

        },
        update: function (element, valueAccessor, allBindingsAccessor, data, context) {

        },
        targetIndex: null,
        afterMove: null,
        beforeMove: null,
        options: {}
    };

});
