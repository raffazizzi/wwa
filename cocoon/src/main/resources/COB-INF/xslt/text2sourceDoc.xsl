<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:wwa="http://www.whitmanarchive.org/namespace"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="2.0">
    
    <!-- From text-oriented TEI to document-oriented -->
    
    <!-- Identity transform -->
    <xsl:template match='@*|node()'>
        <xsl:copy>
            <xsl:apply-templates select='@*|node()'/>
        </xsl:copy>
    </xsl:template>
    
    <!-- METADATA Adjustments -->
    <xsl:template match="tei:handNote">
        <xsl:copy>
            <xsl:attribute name="scribeRef">
                <xsl:choose>
                    <xsl:when test="lower-case(@scribe)='walt_whitman' or @scribeRef = '#ww'">
                        <xsl:text>#ww</xsl:text>
                    </xsl:when>
                    <xsl:when test="lower-case(@scribe)='unknown' or @scribeRef = '#unk'">
                        <xsl:text>#unk</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>#unk</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="@* except @scribeRef | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- TOP LEVEL transformations -->
    
    <xsl:template match="tei:text">
        <sourceDoc xmlns="http://www.tei-c.org/ns/1.0" wwa:was="tei:text">
            <xsl:apply-templates select="@*|node()"/>
        </sourceDoc>
    </xsl:template>
    
    <xsl:template match="tei:body">
            <xsl:apply-templates select="@*|node()"/>        
    </xsl:template>
    
    <!-- TEXT- to DOCUMENT-FOCUSED transformations -->
    
    <!-- Line-level elements -->
    <xsl:template match="tei:item[ancestor::tei:text] | tei:l[ancestor::tei:text]">
        <line xmlns="http://www.tei-c.org/ns/1.0" rend="indent1">
            <xsl:apply-templates select="@*|node()"/>
        </line>
    </xsl:template>
    
    <xsl:template match="tei:p[ancestor::tei:text] 
        | tei:q[ancestor::tei:text] 
        | tei:ab[ancestor::tei:text] 
        | tei:byline[ancestor::tei:text]">        
        
        <xsl:variable name="anchor_id" select="generate-id()"/>
        <milestone xmlns="http://www.tei-c.org/ns/1.0" unit="tei:{local-name()}" spanTo="#{$anchor_id}"/>
        
        <xsl:apply-templates select="node()"/>
        
        <anchor xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$anchor_id}"/>
        
    </xsl:template>
    
    <!-- For now, we flatten choices -->
    <xsl:template match="tei:choice[ancestor::tei:text][tei:sic or tei:orig]">
        <seg wwa:was="{if (tei:sic) then 'tei:sic' else 'tei:orig'}" xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="tei:sic/node() | tei:orig/node()"/>
        </seg>
    </xsl:template>
    
    <!-- subst to mod -->
    <xsl:template match="tei:subst">
        <mod xmlns="http://www.tei-c.org/ns/1.0" wwa:was="tei:subst">
            <xsl:apply-templates select="@*|node()"/>
        </mod>
    </xsl:template>
    
    <!-- Change attribute values to SGA conventions -->
    <xsl:template match="@place">
        <xsl:attribute name="place">
            <xsl:choose>
                <xsl:when test=".='infralinear'">
                    <xsl:text>sublinear</xsl:text>
                </xsl:when>
                <xsl:when test=".=('over', 'supralinear')">
                    <xsl:text>superlinear</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>        
    </xsl:template>
    
    <!-- generalize semantics -->
    <xsl:template match="tei:div[ancestor::tei:text] 
        | tei:div1[ancestor::tei:text] 
        | tei:list[ancestor::tei:text] 
        | tei:head[ancestor::tei:text] 
        | tei:lg[ancestor::tei:text] ">
        <xsl:variable name="anchor_id" select="generate-id()"/>
        <milestone xmlns="http://www.tei-c.org/ns/1.0" unit="tei:{local-name()}" spanTo="#{$anchor_id}">
            <xsl:if test="count(@* except @xml:id) > 0">
                <xsl:attribute name="wwa:attrs">
                    <xsl:for-each select="@* except @xml:id">
                        <xsl:value-of select="concat(local-name(),':',.,',')"/>
                    </xsl:for-each>
                </xsl:attribute>
            </xsl:if>  
            <xsl:apply-templates select="@xml:id"/>
        </milestone>    
        <xsl:apply-templates select="node()"/>
        
        <anchor xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$anchor_id}"/>
        
    </xsl:template>
    
    <!-- Make spans into metamarks -->
    <xsl:template match="tei:span[@to]">
        <add hand="{@hand}" xmlns="http://www.tei-c.org/ns/1.0">
            <metamark xmlns="http://www.tei-c.org/ns/1.0" function="marginalia" spanTo="{@to}" wwa:was="tei:span">
                <xsl:apply-templates select="@* except @hand except @from except @to|node()"/>
            </metamark>
        </add>        
    </xsl:template>
    
    <!-- make notes into additions -->
    <xsl:template match="tei:note[ancestor::tei:text]">
        <xsl:choose>
            <xsl:when test="ancestor::tei:zone[@type='pasteon'] and @place='top'">
                <xsl:choose>
                    <xsl:when test="@resp">
                        <add hand="{@resp}" xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:attribute name="hand" select="@resp"/>
                            <xsl:apply-templates select="node()"/>
                        </add>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="@subtype='nested_anno'">
                <xsl:choose>
                    <xsl:when test="@resp">
                        <add hand="{@resp}" xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:attribute name="hand" select="@resp"/>
                            <xsl:apply-templates select="node()"/>
                        </add>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:when>
            <xsl:when test="not(@type='authorial') and not(@place)">
                <xsl:choose>
                    <xsl:when test="@resp">
                        <add hand="{@resp}" xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:attribute name="hand" select="@resp"/>
                            <xsl:apply-templates select="@* except @resp|node()"/>
                        </add>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>            
            <xsl:when test="not(@place) or @type='authorial_footnote'">
                <xsl:choose>
                    <xsl:when test="@resp">
                        <add hand="{@resp}" xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:attribute name="hand" select="@resp"/>
                            <xsl:apply-templates select="node()"/>
                        </add>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="not(@type='authorial')">
                <xsl:choose>
                    <xsl:when test="@resp">
                        <add hand="{@resp}" xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:attribute name="hand" select="@resp"/>
                            <xsl:apply-templates select="node()"/>
                        </add>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <anchor xmlns="http://www.tei-c.org/ns/1.0" type="marginalia" xml:id="{generate-id()}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--<xsl:template match="tei:lb[ancestor::tei:zone[not(descendant::tei:fw)]][following::tei:note[ancestor::tei:text][@type='authorial'][@place]]">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="following::tei:note[ancestor::tei:text][@type='authorial'][@place][1]/generate-id()"/>
            <xsl:apply-templates select="@* except @xml:id | node()"/>
        </xsl:copy>
    </xsl:template>-->
    
    <!-- CLEANUP and ADJUSTMENTS from previous transformations -->
    
    <!-- cleanup empty blocks -->
    <xsl:template match="tei:surface[count(*)=1][tei:zone[not(*) and not(text()[normalize-space()])]]"/>
    
    <xsl:template match="tei:pb | tei:cb"/>
    
    <xsl:template name="noteToAdd">
        <add xmlns="http://www.tei-c.org/ns/1.0" target="#{generate-id()}">
            <xsl:if test="@resp">
                <xsl:attribute name="hand" select="@resp"/>
            </xsl:if>
            <xsl:copy>
                <xsl:apply-templates select="@* except @place|node()"/>
            </xsl:copy>            
        </add>
    </xsl:template>
    
    <xsl:template match="tei:surface[descendant::tei:pb]">
        <xsl:copy>
            <xsl:attribute name="ulx">0</xsl:attribute>
            <xsl:attribute name="uly">0</xsl:attribute>
            <xsl:attribute name="lrx">4200</xsl:attribute>
            <xsl:attribute name="lry">6000</xsl:attribute>
            <xsl:attribute name="wwa:was"><xsl:text>tei:pb</xsl:text></xsl:attribute>
            <xsl:apply-templates select="@*"/>
            
            <graphic xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="url">
                    <xsl:analyze-string select="@facs" regex="(.*)\.\w+"> <!-- important, keep lazy! -->
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                            <xsl:text>.jp2</xsl:text>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:attribute>
            </graphic>
            
            <!-- Top-level annotations -->
            
            <xsl:choose>                
                <xsl:when test="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top'][tokenize(@place, ' ')=('left', 'right')]">
                    <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top'][tokenize(@place, ' ')='left']">
                        <zone type="top_marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:call-template name="noteToAdd"/> 
                        </zone>
                    </xsl:for-each>            
                    <!-- stick @place top only in the middle -->
                    <xsl:for-each select="descendant::tei:note[@type='authorial'][@place='top']">
                        <zone type="top_marginalia_middle" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:call-template name="noteToAdd"/> 
                        </zone>
                    </xsl:for-each>
                    <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top'][tokenize(@place, ' ')='right']">
                        <zone type="top_marginalia_right" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:call-template name="noteToAdd"/>   
                        </zone>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="descendant::tei:note[@type='authorial'][@place='top']">
                    <xsl:for-each select="descendant::tei:note[@type='authorial'][@place='top']">
                        <zone type="top_marginalia" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:call-template name="noteToAdd"/> 
                        </zone>
                    </xsl:for-each> 
                </xsl:when>
                <!-- Only accounting for two columns at the moment... -->
                <xsl:otherwise>
                    <xsl:for-each select="tei:zone[descendant::tei:cb][1][descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top']]">
                        <zone type="top_marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top']">
                                <xsl:call-template name="noteToAdd"/>                             
                            </xsl:for-each>
                        </zone>
                    </xsl:for-each>
                    <xsl:for-each select="tei:zone[descendant::tei:cb][2][descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top']]">
                        <zone type="top_marginalia_right" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='top']">
                                <xsl:call-template name="noteToAdd"/>                             
                            </xsl:for-each>
                        </zone>
                    </xsl:for-each>
                    <!-- Or on top without columns (defaults to left) -->
                    <xsl:if test="not(descendant::tei:cb)">
                        <xsl:for-each select="descendant::tei:note[@type='authorial'][not(ancestor::tei:zone[@type='pasteon'])][tokenize(@place, ' ')='top']">
                            <zone type="top_marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                                <xsl:call-template name="noteToAdd"/>   
                            </zone>
                        </xsl:for-each>
                    </xsl:if>
                    
                </xsl:otherwise>
            </xsl:choose>
            
            
            <!-- left margin annos -->
            <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='left'][not(tokenize(@place, ' ')=('top','bottom'))]">
                <zone type="marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                    <xsl:call-template name="noteToAdd"/>    
                </zone>
            </xsl:for-each>
            
            <!-- right margin annos -->
            <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='right'][not(tokenize(@place, ' ')=('top','bottom'))]">
                <zone type="marginalia_right" xmlns="http://www.tei-c.org/ns/1.0" >
                    <xsl:call-template name="noteToAdd"/>         
                </zone>
            </xsl:for-each>
            
            
            <!-- content (main, columns) -->
            <xsl:apply-templates select="node()"/>            
            
            
            <!-- bottom-level annotations... -->
            
            <xsl:choose>
                <xsl:when test="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom'][tokenize(@place, ' ')=('left', 'right')]">
                    <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom'][tokenize(@place, ' ')='left']">
                        <zone type="bottom_marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:call-template name="noteToAdd"/> 
                        </zone>
                    </xsl:for-each>            
                    
                    <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom'][tokenize(@place, ' ')='right']">
                        <zone type="bottom_marginalia_right" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:call-template name="noteToAdd"/>   
                        </zone>
                    </xsl:for-each>
                </xsl:when>
                <!-- Only accounting for two columns at the moment... -->
                <xsl:otherwise>
                    <xsl:for-each select="tei:zone[descendant::tei:cb][1][descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom']]">
                        <zone type="bottom_marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom']">
                                <xsl:call-template name="noteToAdd"/>                             
                            </xsl:for-each>
                        </zone>
                    </xsl:for-each>
                    <xsl:for-each select="tei:zone[descendant::tei:cb][2][descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom']]">
                        <zone type="bottom_marginalia_right" xmlns="http://www.tei-c.org/ns/1.0" >
                            <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom']">
                                <xsl:call-template name="noteToAdd"/>                             
                            </xsl:for-each>
                        </zone>
                    </xsl:for-each>
                    <!-- Or on bottom without columns (defaults to left) -->
                    <xsl:if test="not(descendant::tei:cb)">
                        <xsl:for-each select="descendant::tei:note[@type='authorial'][tokenize(@place, ' ')='bottom']">
                            <zone type="bottom_marginalia_left" xmlns="http://www.tei-c.org/ns/1.0" >
                                <xsl:call-template name="noteToAdd"/>   
                            </zone>
                        </xsl:for-each>
                    </xsl:if>
                    
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:copy>        
    </xsl:template>    
    
    <!-- ZONES -->
    
    <!-- match the first column, replace it with a wrapper and pull in the following siblings -->
    <xsl:template match="tei:zone[descendant::tei:cb][following-sibling::tei:zone[descendant::tei:cb]]
                                                     [not(preceding-sibling::tei:zone[descendant::tei:cb])]">
        <xsl:for-each select="self::* | following-sibling::tei:zone[descendant::tei:cb]">
            <xsl:copy>
                <xsl:attribute name="wwa:was"><xsl:text>tei:cb</xsl:text></xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:choose>
                        <xsl:when test="descendant::tei:cb/@type='end'">
                            <xsl:text>main_part</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>column</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:variable name="totcols" select="count(ancestor::tei:surface//tei:zone[descendant::tei:cb[not(@type='end')]])"/>
                <xsl:attribute name="rend">
                    <xsl:choose>
                        <xsl:when test="descendant::tei:cb/@type='end'">
                            <xsl:text> col-12</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text> col-</xsl:text><xsl:value-of select="12 div $totcols"/> 
                            
                            <xsl:if test="preceding-sibling::tei:zone[descendant::tei:cb]">
                                <xsl:text> new</xsl:text>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                
                </xsl:attribute>
                <!-- preserve latest handshift -->
                <xsl:apply-templates select="@* except @type except @rend"/>
                <xsl:sequence select="preceding::tei:handShift[1]"/>
                <xsl:choose>
                    <xsl:when test="descendant::tei:cb/@type='end'">
                        <xsl:apply-templates select="node() except tei:zone[@type='pasteon']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="tei:zone[descendant::tei:cb][preceding-sibling::tei:zone[descendant::tei:cb]]" />        
    
    
    <xsl:template match="tei:zone[not(descendant::tei:cb)]">
        <xsl:choose>
            <xsl:when test="descendant::tei:fw and not(@type='pasteon') and ancestor::tei:surface//tei:zone[descendant::tei:cb]">
                <xsl:apply-templates select="node()"/>
            </xsl:when>
            <!-- main + columns -->
            <xsl:when test="not(@type='pasteon') and ancestor::tei:surface//tei:zone[descendant::tei:cb]">
                <xsl:copy>
                    <xsl:attribute name="type">main</xsl:attribute>
                    <xsl:attribute name="rend"> col-12</xsl:attribute>
                    <xsl:apply-templates select="@* except @type except @rend|node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- book format in one column (only if there are no columns!) -->
            <xsl:when test="descendant::tei:fw and not(@type='pasteon') and not(ancestor::tei:surface//tei:zone[descendant::tei:cb])">
                <xsl:apply-templates select="tei:fw"/>
                <xsl:copy>
                    <xsl:attribute name="type">main</xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="ancestor::tei:surface//tei:zone[@type='pasteon'][contains(@rend, 'col-')]">
                            <xsl:attribute name="rend">
                                <xsl:value-of select="@rend"/>
                                <xsl:text> col-12</xsl:text>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="@rend"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="@* except @rend" />
                    <!-- preserve latest handshift -->
                    <xsl:sequence select="preceding::tei:handShift[1]"/>
                    <xsl:apply-templates select="node() except tei:zone[@type='pasteon'] except tei:fw"/>
                </xsl:copy>
                <!-- Keep pasteons in separate zones -->
                <xsl:apply-templates select="tei:zone[@type='pasteon']"/>
            </xsl:when>
            <!-- when there are no columns, make the only zone a "main" zone -->
            <xsl:when test="not(descendant::tei:fw) and not(@type='pasteon')">
                <xsl:copy>
                    <xsl:attribute name="type">main</xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="ancestor::tei:surface//tei:zone[@type='pasteon'][contains(@rend, 'col-')]">
                            <xsl:attribute name="rend">
                                <xsl:value-of select="@rend"/>
                                <xsl:text> col-12</xsl:text>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="@rend"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="@* except @rend" />
                    <!-- preserve latest handshift -->
                    <xsl:sequence select="preceding::tei:handShift[1]"/>
                    <xsl:apply-templates select="node() except tei:zone[@type='pasteon']"/>
                </xsl:copy>
                <!-- Keep pasteons in separate zones -->
                <xsl:apply-templates select="tei:zone[@type='pasteon']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
        

    
    <!-- Deal with nested pasteons (FLAT ONLY) -->
    <xsl:template match="tei:add[@rend='pasteon'][ancestor::tei:zone[@type=('pasteon', 'end')]]">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    <xsl:template match="tei:floatingText[ancestor::tei:zone[@type=('pasteon', 'end')]]">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    <xsl:template match="tei:surface[ancestor::tei:floatingText][ancestor::tei:zone[@type=('pasteon', 'end')]]">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <xsl:template match="tei:fw[contains(@place,'top')][not(ancestor::tei:zone[@type='pasteon'])]">
        <!-- kill nested running heads for now, no SC support -->
        <zone type="running_head" xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="node()"/>
        </zone>
    </xsl:template>
    
    <xsl:template match="tei:fw[contains(@place,'bottom')]">
        <zone type="running_bottom" xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="node()"/>
        </zone>
    </xsl:template>
        
    <xsl:template match="tei:surface[normalize-space()=''][count(*)=1][tei:lb]"/>
    
    <xsl:template match="tei:lb[not(ancestor::tei:zone)]"/>
    
</xsl:stylesheet>