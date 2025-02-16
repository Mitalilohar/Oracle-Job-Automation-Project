CREATE OR REPLACE PACKAGE APPS.xx_job_auto_utils_pkg
AS
   -- Function to get existing jobs quantity
   FUNCTION xx_existing_jobs_qty_func (
      p_order_number   IN   VARCHAR2,
      p_line_number    IN   VARCHAR2,
      p_order_item     IN   VARCHAR2
   )
      RETURN NUMBER;

   -- Function to get created job quantity
   FUNCTION xx_job_created_qty_func (
      p_order_number   IN   VARCHAR2,
      p_line_number    IN   VARCHAR2,
      p_order_item     IN   VARCHAR2
   )
      RETURN NUMBER;

   -- Function to get pending quantity
   FUNCTION xx_pending_qty_func (
      p_order_number      IN   VARCHAR2,
      p_line_number       IN   VARCHAR2,
      p_order_item        IN   VARCHAR2,
      p_shipment_number   IN   VARCHAR2
   )
      RETURN NUMBER;

   -- Function to get open sales order quantity
   FUNCTION xx_get_open_so_qty_func (
      p_inventory_item_id   IN   NUMBER,
      p_org_id              IN   NUMBER,
      p_from_date           IN   DATE DEFAULT NULL,
      p_to_date             IN   DATE DEFAULT NULL
   )
      RETURN NUMBER;

   -- Function to extract Sales Order (SO) number
   FUNCTION xx_extract_so_number (attribute3 IN VARCHAR2)
      RETURN VARCHAR2;

   -- Function to extract Line Number
   FUNCTION xx_extract_line_no (p_input IN VARCHAR2)
      RETURN VARCHAR2;

   -- Function to extract Shipment Number
   FUNCTION xx_extract_shipno (attribute3 IN VARCHAR2)
      RETURN VARCHAR2;

   -- Procedure to create BOM items job
   PROCEDURE xx_bom_items_job_prc (
      ln_inventory_item_id   IN   NUMBER,
      ln_organization_id     IN   NUMBER
   );

   PROCEDURE xx_calculate_open_demand_prc (
      p_organization_id     IN       NUMBER,
      p_inventory_item_id   IN       NUMBER,
      p_from_date           IN       DATE,
      p_to_date             IN       DATE,
      o_resultant_sum       OUT      NUMBER
   );

   FUNCTION xx_get_child_existing_jobs (
      p_inventory_item_id         IN   NUMBER,
      p_org_id                    IN   NUMBER,
      input_block_ssd_from_date   IN   DATE DEFAULT NULL,
      input_block_ssd_to_date     IN   DATE DEFAULT NULL
   )
      RETURN NUMBER;

   PROCEDURE xx_calculate_onhand_qty_prc (
      p_inventory_item_id   IN       NUMBER,
      p_organization_id     IN       NUMBER,
      p_total_onhand_oh     OUT      NUMBER
   );
END xx_job_auto_utils_pkg;
/


/* Formatted on 2025/01/15 17:20 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY APPS.xx_job_auto_utils_pkg
AS
   -- Function to extract Sales Order (SO) number
   FUNCTION xx_extract_so_number (attribute3 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      so_number   VARCHAR2 (50);
   BEGIN
      IF attribute3 IS NOT NULL
      THEN
         so_number := SUBSTR (attribute3, 1, INSTR (attribute3, '.') - 1);

         IF INSTR (attribute3, '.') = 0
         THEN
            so_number := attribute3;
         END IF;
      END IF;

      RETURN so_number;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END xx_extract_so_number;

   -- Function to extract Line Number
   FUNCTION xx_extract_line_no (p_input IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_result   VARCHAR2 (100);
   BEGIN
      v_result :=
         CASE
            WHEN INSTR (p_input, '.', INSTR (p_input, '.') + 1) > 0
               THEN SUBSTR (p_input,
                            INSTR (p_input, '.') + 1,
                              INSTR (p_input, '.', INSTR (p_input, '.') + 1)
                            - INSTR (p_input, '.')
                            - 1
                           )
            ELSE SUBSTR (p_input, INSTR (p_input, '.') + 1)
         END;
      RETURN v_result;
   END xx_extract_line_no;

   -- Function to extract Shipment Number
   FUNCTION xx_extract_shipno (attribute3 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      shipno   VARCHAR2 (50);
   BEGIN
      IF attribute3 IS NOT NULL
      THEN
         shipno := SUBSTR (attribute3, INSTR (attribute3, '.', 1, 2) + 1);

         IF INSTR (attribute3, '.', 1, 2) = 0
         THEN
            shipno := NULL;
         END IF;
      END IF;

      RETURN shipno;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END xx_extract_shipno;

   -- Function to get existing jobs quantity
   FUNCTION xx_existing_jobs_qty_func (
      p_order_number   IN   VARCHAR2,
      p_line_number    IN   VARCHAR2,
      p_order_item     IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      v_qty   NUMBER;
   BEGIN
      SELECT SUM (wj.net_quantity)
        INTO v_qty
        FROM wip_discrete_jobs wj, mtl_system_items_b msi
       WHERE xx_extract_so_number (wj.attribute3) = p_order_number
         AND NVL (xx_extract_line_no (wj.attribute3), p_line_number) =
                                                                 p_line_number
         AND regexp_count (wj.attribute3, '\.') = 1
         AND msi.segment1 = p_order_item
         AND wj.organization_id = msi.organization_id
         AND wj.primary_item_id = msi.inventory_item_id
         AND wj.status_type IN (1, 3);

      RETURN NVL (v_qty, 0);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END xx_existing_jobs_qty_func;

   -- Function to get created job quantity
   FUNCTION xx_job_created_qty_func (
      p_order_number   IN   VARCHAR2,
      p_line_number    IN   VARCHAR2,
      p_order_item     IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      v_qty   NUMBER;
   BEGIN
      SELECT SUM (wj.net_quantity)
        INTO v_qty
        FROM wip_discrete_jobs wj, mtl_system_items_b msi
       WHERE xx_extract_so_number (wj.attribute3) = p_order_number
         AND NVL (xx_extract_line_no (wj.attribute3), p_line_number) =
                                                                 p_line_number
         AND regexp_count (wj.attribute3, '\.') = 2
         AND msi.segment1 = p_order_item
         AND wj.organization_id = msi.organization_id
         AND wj.primary_item_id = msi.inventory_item_id
         AND wj.status_type IN (1, 3);

      RETURN NVL (v_qty, 0);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END xx_job_created_qty_func;

   -- Function to get pending quantity
   FUNCTION xx_pending_qty_func (
      p_order_number      IN   VARCHAR2,
      p_line_number       IN   VARCHAR2,
      p_order_item        IN   VARCHAR2,
      p_shipment_number   IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      v_pending_qty         NUMBER;
      v_existing_jobs_qty   NUMBER;
      v_created_jobs_qty    NUMBER;
   BEGIN
      v_existing_jobs_qty :=
         xx_existing_jobs_qty_func (p_order_number,
                                    p_line_number,
                                    p_order_item
                                   );
      v_created_jobs_qty :=
         xx_job_created_qty_func (p_order_number, p_line_number, p_order_item);

      SELECT CASE
                WHEN v_existing_jobs_qty <> 0
                   THEN GREATEST (ool.ordered_quantity - v_existing_jobs_qty,
                                  0
                                 )
                WHEN v_created_jobs_qty <> 0
                   THEN GREATEST (ool.ordered_quantity - v_created_jobs_qty,
                                  0)
                ELSE ool.ordered_quantity
             END
        INTO v_pending_qty
        FROM oe_order_lines_all ool, oe_order_headers_all ooh
       WHERE ool.header_id = ooh.header_id
         AND ooh.order_number = p_order_number
         AND ool.line_number = p_line_number
         AND ool.shipment_number = p_shipment_number
         AND ool.ordered_item NOT LIKE 'WS%'
         AND ool.flow_status_code NOT IN ('CLOSED', 'CANCELLED');

      RETURN v_pending_qty;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      WHEN OTHERS
      THEN
         RETURN 0;
   END xx_pending_qty_func;

   -- Function to get open SO quantity
   FUNCTION xx_get_open_so_qty_func (
      p_inventory_item_id   IN   NUMBER,
      p_org_id              IN   NUMBER,
      p_from_date           IN   DATE DEFAULT NULL,
      p_to_date             IN   DATE DEFAULT NULL
   )
      RETURN NUMBER
   IS
      v_total_ordered_quantity   NUMBER := 0;
      v_total_shipped_quantity   NUMBER := 0;
   BEGIN
      SELECT SUM (ol.ordered_quantity)
        INTO v_total_ordered_quantity
        FROM oe_order_lines_all ol JOIN oe_order_headers_all oh
             ON ol.header_id = oh.header_id
       WHERE ol.inventory_item_id = p_inventory_item_id
         AND ol.flow_status_code NOT IN ('CLOSED', 'CANCELLED','ENTERED','BOOKED')
         AND ol.schedule_ship_date IS NOT NULL
         AND ol.ship_from_org_id = p_org_id;

      SELECT SUM (NVL (ol.shipped_quantity, 0))
        INTO v_total_shipped_quantity
        FROM oe_order_lines_all ol JOIN oe_order_headers_all oh
             ON ol.header_id = oh.header_id
       WHERE ol.inventory_item_id = p_inventory_item_id
         AND ol.flow_status_code NOT IN ('CLOSED', 'CANCELLED','ENTERED','BOOKED')
         AND ol.schedule_ship_date IS NOT NULL
         AND ol.ship_from_org_id = p_org_id;

      IF (v_total_ordered_quantity - v_total_shipped_quantity) < 0
      THEN
         RETURN GREATEST (v_total_ordered_quantity, v_total_shipped_quantity);
      END IF;

      RETURN v_total_ordered_quantity - v_total_shipped_quantity;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      WHEN OTHERS
      THEN
         RAISE;
   END xx_get_open_so_qty_func;

   PROCEDURE xx_bom_items_job_prc (
      ln_inventory_item_id   NUMBER,
      ln_organization_id     NUMBER
   )
   IS
      porg_id              NUMBER;
      porder_by            NUMBER;
      plist_id             NUMBER;
      pgrp_id              NUMBER;
      psession_id          NUMBER;
      plevels_to_explode   NUMBER;
      pbom_or_eng          NUMBER;
      pimpl_flag           NUMBER;
      pexplode_option      NUMBER;
      pmodule              NUMBER;
      pcst_type_id         NUMBER;
      pstd_comp_flag       NUMBER;
      pexpl_qty            NUMBER;
      preport_option       NUMBER;
      preq_id              NUMBER;
      plock_flag           NUMBER;
      prollup_option       NUMBER;
      palt_rtg_desg        VARCHAR2 (1500);
      palt_desg            VARCHAR2 (1500);
      prev_date            DATE;
      perr_msg             VARCHAR2 (1500);
      perror_code          NUMBER;
      pcst_rlp_id          NUMBER;
      pverify_flag         NUMBER;
      pplan_factor_flag    NUMBER;
      pincl_lt_flag        NUMBER;
--
      ln_item_name         mtl_system_items_b.segment1%TYPE;

      CURSOR cur_list_id
      IS
         SELECT bom_lists_s.NEXTVAL
           FROM DUAL;

      CURSOR cur_grp_id
      IS
         SELECT bom_explosion_temp_s.NEXTVAL
           FROM DUAL;
   BEGIN
      BEGIN
         OPEN cur_list_id;

         FETCH cur_list_id
          INTO plist_id;

         CLOSE cur_list_id;

         OPEN cur_grp_id;

         FETCH cur_grp_id
          INTO pgrp_id;

         CLOSE cur_grp_id;

         porg_id := ln_organization_id;
         porder_by := 1;
         psession_id := -1;
         plevels_to_explode := 10;
         pbom_or_eng := 1;
         pimpl_flag := 1;
         pexplode_option := 2;
         -- 1 = ALL, 2 = Current, 3 = Current and future
         pmodule := 2;
         pcst_type_id := 2;
         pstd_comp_flag := 1;
         pexpl_qty := 1;
         preport_option := -1;
         preq_id := 0;
         plock_flag := -1;
         prollup_option := -1;
         palt_rtg_desg := '';
         palt_desg := '';
         prev_date := SYSDATE;
         --to_date('31-JAN-2016 00:00:00','DD-MON-YYYY hh24:mi:ss');--SYSDATE;
         pcst_rlp_id := 0;
         pverify_flag := 0;
         pplan_factor_flag := 1;
         pincl_lt_flag := 2;

         DELETE FROM bom_lists;

         DELETE FROM bom_explosion_temp;

         INSERT INTO bom_lists
                     (sequence_id, assembly_item_id,
                      organization_id
                     )
              VALUES (TO_CHAR (plist_id), ln_inventory_item_id,
                      ln_organization_id
                     );

         bompexpl.explosion_report (org_id                 => porg_id,
                                    order_by               => porder_by,
                                    list_id                => plist_id,
                                    grp_id                 => pgrp_id,
                                    session_id             => psession_id,
                                    levels_to_explode      => plevels_to_explode,
                                    bom_or_eng             => pbom_or_eng,
                                    impl_flag              => pimpl_flag,
                                    explode_option         => pexplode_option,
                                    module                 => pmodule,
                                    cst_type_id            => pcst_type_id,
                                    std_comp_flag          => pstd_comp_flag,
                                    expl_qty               => pexpl_qty,
                                    report_option          => preport_option,
                                    req_id                 => preq_id,
                                    lock_flag              => plock_flag,
                                    rollup_option          => prollup_option,
                                    alt_rtg_desg           => palt_rtg_desg,
                                    alt_desg               => palt_desg,
                                    rev_date               => prev_date,
                                    err_msg                => perr_msg,
                                    ERROR_CODE             => perror_code,
                                    cst_rlp_id             => pcst_rlp_id,
                                    verify_flag            => pverify_flag,
                                    plan_factor_flag       => pplan_factor_flag,
                                    incl_lt_flag           => pincl_lt_flag
                                   );

         DELETE FROM xx_job_bom_explosion_temp;

         INSERT INTO xx_job_bom_explosion_temp
                     (component_item_id, organization_id, bom_quantity,
                      fg_qty, GROUP_ID, assembly_item_id, fg_item_id,
                      wip_supply_type, item_cost, lev, ope_seq_num, fg_name,
                      component_code, supply_subinventory)
            SELECT component_item_id, organization_id, component_quantity,
                   extended_quantity, GROUP_ID, assembly_item_id,
                   a.top_item_id, wip_supply_type, item_cost, plan_level,
                   a.item_num, sort_order, component_code,
                   supply_subinventory
              FROM bom_explosion_temp a
             WHERE GROUP_ID = pgrp_id AND organization_id = ln_organization_id;

         COMMIT;
      END;
   END;

   PROCEDURE xx_calculate_open_demand_prc (
      p_organization_id     IN       NUMBER,
      p_inventory_item_id   IN       NUMBER,
      p_from_date           IN       DATE,
      p_to_date             IN       DATE,
      o_resultant_sum       OUT      NUMBER
   )
   IS
      o_resultant_sum_temp   NUMBER := 0;
-- Temporary variable to hold sum
   BEGIN
      -- Clear the temporary BOM table
      SELECT NVL (SUM (GREATEST (wro.required_quantity - wro.quantity_issued,
                                 0
                                )
                      ),
                  0
                 )
        INTO o_resultant_sum_temp
        FROM wip_discrete_jobs_v wdj,
             wip_requirement_operations wro,
             mtl_system_items_b msi
       WHERE wdj.primary_item_id = msi.inventory_item_id
         AND wdj.organization_id = msi.organization_id
         AND wdj.wip_entity_id = wro.wip_entity_id
         AND wdj.status_type IN (1, 3)
         AND wro.inventory_item_id = p_inventory_item_id
         AND msi.organization_id = p_organization_id;

      -- Set the OUT parameter with the calculated sum
      o_resultant_sum := o_resultant_sum_temp;
      -- Log the resultant (optional)
      DBMS_OUTPUT.put_line ('Resultant Sum: ' || o_resultant_sum_temp);
      -- Commit the changes
      COMMIT;
   END xx_calculate_open_demand_prc;

   FUNCTION xx_get_child_existing_jobs (
      p_inventory_item_id         IN   NUMBER,
      p_org_id                    IN   NUMBER,
      input_block_ssd_from_date   IN   DATE DEFAULT NULL,
      input_block_ssd_to_date     IN   DATE DEFAULT NULL
   )
      RETURN NUMBER
   IS
      v_existing_jobs   NUMBER;
   BEGIN
      -- Calculate the sum of net_quantity based on the provided parameters
      SELECT SUM (start_quantity-quantity_completed)
        INTO v_existing_jobs
        FROM wip_discrete_jobs
       WHERE primary_item_id = p_inventory_item_id
         AND organization_id = p_org_id
         AND status_type IN (1, 3)
         AND class_code = 'Standard';

--      AND scheduled_completion_date BETWEEN
--          NVL(input_block_SSD_FROM_DATE, ADD_MONTHS(SYSDATE, -2))
--          AND NVL(input_block_SSD_to_DATE, ADD_MONTHS(SYSDATE, 2));

      -- Return the result
      RETURN v_existing_jobs;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         -- Handle the case where no rows are found
         RETURN 0;                                -- Or another default value
      WHEN OTHERS
      THEN
         -- Handle unexpected errors
         RETURN NULL;
   END xx_get_child_existing_jobs;

   PROCEDURE xx_calculate_onhand_qty_prc (
      p_inventory_item_id   IN       NUMBER,
      p_organization_id     IN       NUMBER,
      p_total_onhand_oh     OUT      NUMBER
   )
   AS
      v_revision            VARCHAR2 (10);
      v_subinventory_code   VARCHAR2 (15);
      v_res_oh              NUMBER;
      v_res_atr             NUMBER;
      v_total_onhand        NUMBER        := 0;
      v_org_code            VARCHAR2 (10);

      CURSOR subinventory_cursor
      IS
         SELECT   msi.secondary_inventory_name
             FROM mtl_secondary_inventories msi,
                  mtl_parameters mp,
                  mtl_material_statuses_vl mmst
            WHERE msi.organization_id = mp.organization_id
              AND msi.status_id = mmst.status_id
              AND mmst.availability_type = 1
              AND mmst.enabled_flag = 1
              AND mp.organization_code = v_org_code
         ORDER BY msi.secondary_inventory_name;
   BEGIN
      SELECT organization_code
        INTO v_org_code
        FROM mtl_parameters
       WHERE organization_id = p_organization_id;

      -- Fetch the latest revision
      SELECT MAX (revision)
        INTO v_revision
        FROM mtl_item_revisions
       WHERE inventory_item_id = p_inventory_item_id
         AND organization_id = p_organization_id
         AND effectivity_date <= SYSDATE;

      -- Loop through all subinventory codes
      FOR subinv_rec IN subinventory_cursor
      LOOP
         v_subinventory_code := subinv_rec.secondary_inventory_name;
         -- Call the existing procedure for each subinventory code
         apps.xx_onhand_quantity_prc (p_org_id       => p_organization_id,
                                      p_item_id      => p_inventory_item_id,
                                      p_rev          => v_revision,
                                      p_subinv       => v_subinventory_code,
                                      p_res_oh       => v_res_oh,
                                      p_res_atr      => v_res_atr
                                     );
         -- Accumulate the total on-hand quantity
         v_total_onhand := v_total_onhand + NVL (v_res_oh, 0);
         DBMS_OUTPUT.put_line ('Subinventory: ' || v_subinventory_code);
      /*DBMS_OUTPUT.PUT_LINE (
         'Subinventory: '
      || v_subinventory_code
      || ' | Onhand: '
      || v_res_oh
      || ' | Available To Reserve: '
      || v_res_atr);*/
      END LOOP;

      -- Set the OUT parameter to the total on-hand quantity
      p_total_onhand_oh := v_total_onhand;
   END xx_calculate_onhand_qty_prc;
END xx_job_auto_utils_pkg;
/
