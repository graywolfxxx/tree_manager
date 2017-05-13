(function ($) {
    if ($.fn.SimpleTree) {
        return;
    }

    var defaults = {};

    var SimpleTree = function (element, options) {
        this.$element = $(element);
        this.options  = $.extend(true, {}, defaults, options || {});
        if (typeof(this.options.expanded) == 'undefined' || this.options.expanded == null) {
            this.options.expanded = -1;
        }
        if (typeof(this.options.cur_id) == 'undefined' || this.options.cur_id == null) {
            this.options.cur_id = 0;
        }
        var data = options.data;
        delete options['data'];
        this.add_node(0, data);
    };

    SimpleTree.prototype.remove_all = function (pid) {
        pid = pid ? pid : 0;
        var oParent = pid == 0 ? this.$element : this.$element.find("[data-id='" + pid + "']");
        if (!oParent) return 0;
        oParent.children().remove();
    };

    SimpleTree.prototype.remove_node = function (id) {
        if (!id) return 0;
        var oObj = this.$element.find("[data-id='" + id + "']");
        if (!oObj) return 0;
        oObj.remove();
    };

    SimpleTree.prototype.add_node = function (pid, data) {
        pid  = pid ? pid : 0;
        data = data instanceof Array ? data : [];
        if (!data.length) return 0;
        var simpleTree = this;
        var oParent = pid == 0 ? this.$element : this.$element.find("[data-id='" + pid + "']");
        if (!oParent) return 0;
        var depth = pid == 0 ? -1 : oParent.data('depth');
        var oDiv = oParent.children('div')[0], oUl = oParent.children('ul')[0];
        if (!oDiv && pid != 0) {
            oDiv = $('<div class="expander"></div>');
            if (this.options.expanded >= depth) {
                oDiv.toggleClass('expanded');
            }
            oDiv.click(function() {
                $(this).toggleClass('expanded').nextAll('ul:first').toggleClass('expanded');
                return true;
            });
            if (oUl) {
                oDiv.insertBefore(oUl);
            } else {
                oParent.append(oDiv);
            }
        }
        if (!oUl) {
            oUl = pid == 0 ? $('<ul></ul>') : $('<ul class="tree-inner"></ul>');
            if (this.options.expanded >= depth) {
                oUl.toggleClass('expanded');
            }
            oParent.append(oUl);
        }
        var oLi, oTxt;
        for (var i = 0; i < data.length; i++) {
            oLi = $('<li></li>');
            oLi.data('id', data[i].id).attr('data-id', data[i].id);
            oLi.data('pid', data[i].pid || 0).attr('data-pid', data[i].pid || 0);
            oLi.data('depth', depth + 1).attr('data-depth', depth + 1);
            oTxt = $('<span class="tree-text disable-select"></span>');
            oTxt.text(data[i].text);
            oTxt.dblclick(function() {
                var pDiv = $(this).parents('li:first').children('div');
                pDiv.toggleClass('expanded').nextAll('ul:first').toggleClass('expanded');
                return true;
            });
            oTxt.click(function() {
                var oPrnt = $(this).parents('li:first');
                var new_cur_id = oPrnt.data('id');
                if (simpleTree.options.cur_id && new_cur_id && simpleTree.options.cur_id == new_cur_id) {
                    return;
                }
                if (simpleTree.options.cur_id) {
                    simpleTree.$element.find("[data-id='" + simpleTree.options.cur_id + "']").children('span').toggleClass('tree-text-select');
                }
                simpleTree.options.cur_id = new_cur_id;
                $(this).toggleClass('tree-text-select');
                if (simpleTree.options.onChangeElem) {
                    simpleTree.options.onChangeElem.call(simpleTree, {
                        'node': oPrnt.get(0),
                        'selected': $.extend(true, {}, oPrnt.data(), {'text': $(this).text()})
                    });
                }
            })
            oLi.append(oTxt);
            oUl.append(oLi);
            this.add_node(data[i].id, data[i].children);
        }
        return data.length;
    };

//    SimpleTree.prototype.hello = function (args) {
//        console.log('Hello World! Data length: [' + (this.data ? this.data.length : 'ooops') + ']', this.data[0], args);
//    };

    function Plugin(options, args) {
        return this.each(function () {
            var $this      = $(this);
            var simpleTree = $this.data('simpletreeobj');
            if (!simpleTree) {
                simpleTree = typeof options == 'object' ? new SimpleTree(this, options) : new SimpleTree(this);
                $this.data('simpletreeobj', simpleTree);
            } else if (typeof options == 'string') {
                simpleTree[options].call(simpleTree, args);
            }
        });
    };

    $.fn.SimpleTree = Plugin;
})(jQuery);
