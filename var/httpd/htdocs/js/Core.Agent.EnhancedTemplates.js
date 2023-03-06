// --
// OTOBO is a web-based ticketing system for service organisations.
// --
// Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
// Copyright (C) 2019-2022 Rother OSS GmbH, https://otobo.de/
// --
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};


/**
 * @namespace Core.Agent.EnhancedTemplates
 * @memberof Core.Agent
 * @author
 * @description
 *      This namespace contains functions for enhanced templates.
 */
Core.Agent.EnhancedTemplates = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.EnhancedTemplates
     * @function
     * @description
     *      This function initializes the enhanced templates' functionality.
     */
    TargetNS.Init = function () {

        $( "#EnhancedTemplateID" ).change(function() {
            // save original action, so we can later distinguish between the actions that made the ajax request
            let origAction = $('input[name=Action]').val();
            $('#NewPhoneTicket').append('<input type="hidden"  id="OrigAction" name="OrigAction" value="' + origAction + '" />');

            // add AJAXAction Input field, with this we can use a custom action in Core.Ajax.Formupdate
            $('#NewPhoneTicket').append('<input type="hidden"  id="AJAXAction" name="AJAXAction" value="EnhancedTemplates" />');
            Core.AJAX.FormUpdate($('#NewPhoneTicket'), 'AJAXUpdate', 'EnhancedTemplateID', ['RichTextField']);

            Core.UI.TreeSelection.InitDynamicFieldTreeViewRestore();

            // Remove the AJAXAction input field so that future ajax calls will be made to the original action again
            $('#AJAXAction').remove();
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.EnhancedTemplates || {}));
